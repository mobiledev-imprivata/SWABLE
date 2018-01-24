//
//  S3FileManager.swift
//  SWABLE
//
//  Created by Jonathan Cole on 1/22/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CryptoSwift
import Alamofire

/*
 Manages the process of uploading and downloading from an S3 bucket.
 */
final class S3FileManager {

    enum S3Error: Error {
        case invalidDataFormat
        case signingFailed
    }

    struct Credentials {
        var accessKey: String
        var secret: String
    }

    struct Bucket {
        var name: String
        var region: String

        init(name: String, region: String = "us-east-1") {
            self.name = name
            self.region = region
        }
    }

    var credentials: Credentials

    init(credentials: Credentials) {
        self.credentials = credentials
    }
    
    func upload(text: String, to bucket: Bucket, completion: ((Error?) -> Void)? = nil) {
        guard let data = text.data(using: .utf8) else {
            completion?(S3Error.invalidDataFormat)
            return
        }

        let signDate = Date()
        let file = "\(S3FileManager.filenameFormatter.string(from: signDate)).txt"
        
        var headers: HTTPHeaders = [
            "Host": bucket.host,
        ]

        headers.amzTimestamp = S3FileManager.amazonDateFormatter.string(from: signDate)
        headers.amzContentSha = data.sha256().toHexString()

        if let additionalHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders {
            for header in additionalHeaders {
                headers[String(describing: header.key)] = String(describing: header.value)
            }
        }

        do {
            headers["Authorization"] = try authorization(for: file, in: bucket, headers: headers)

            var url = URLComponents()
            url.scheme = "https"
            url.host = bucket.host
            url.path = "/\(bucket.name)/\(file)"

            Alamofire.upload(data, to: url, method: .put, headers: headers).validate(statusCode: 100..<400).responseData { response in
                switch response.result {
                case .success:
                    completion?(nil)
                case .failure(let error):
                    completion?(error)
                }
            }
        }
        catch {
            completion?(S3Error.signingFailed)
        }
    }

}

// MARK: - Private

private extension S3FileManager {

    /// Formats dates as ISO 8601 strings, for use with Amazon S3.
    static var amazonDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.remove(.withColonSeparatorInTime)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
        return formatter
    }()

    static var filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm"
        return formatter
    }()

    /// Value for the Authorization header in any requests this class makes to an S3 bucket.
    /// See: https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
    func authorization(for resource: String, in bucket: Bucket, headers: HTTPHeaders) throws -> String {
        let signature = try sign(resource: resource, in: bucket, headers: headers)
        let headerKeys = headers.amzSorted.map { $0.key.lowercased() }.joined(separator: ";")

        return "AWS4-HMAC-SHA256 Credential=\(credentials.accessKey)/\(headers.amzYMD)/\(bucket.region)/s3/aws4_request,SignedHeaders=\(headerKeys),Signature=\(signature)"
    }

    /// Creates the string for the Signature field of the Authorization header required for privileged access to S3 buckets.
    /// See: https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
    func sign(resource: String, in bucket: Bucket, headers: HTTPHeaders) throws -> String {
        var allowedChars = CharacterSet.urlPathAllowed
        allowedChars.remove(":")

        let canonicalURI = "/\(bucket.name)/\(resource)".addingPercentEncoding(withAllowedCharacters: allowedChars)!
        var canonicalRequest = """
        PUT
        \(canonicalURI)


        """

        for header in headers.amzSorted {
            canonicalRequest += "\(header.key.lowercased()):\(header.value)\n"
        }

        canonicalRequest += """

        \(headers.amzSorted.map { $0.key.lowercased() }.joined(separator: ";"))
        \(headers.amzContentSha)
        """

        let stringToSign = """
        AWS4-HMAC-SHA256
        \(headers.amzTimestamp)
        \(headers.amzYMD)/\(bucket.region)/s3/aws4_request
        \(canonicalRequest.data(using: .utf8)!.sha256().toHexString())
        """

        let dateKey = try HMAC(key: "AWS4\(credentials.secret)", variant: .sha256).authenticate(headers.amzYMD.bytes)
        let dateRegionKey = try HMAC(key: dateKey, variant: .sha256).authenticate(bucket.region.bytes)
        let dateRegionServiceKey = try HMAC(key: dateRegionKey, variant: .sha256).authenticate("s3".bytes)
        let signingKey = try HMAC(key: dateRegionServiceKey, variant: .sha256).authenticate("aws4_request".bytes)

        return try HMAC(key: signingKey, variant: .sha256).authenticate(stringToSign.bytes).toHexString()

    }

}

private extension S3FileManager.Bucket {

    var host: String {
        var host = "s3"
        if region != "us-east-1" {
            host += "-\(region)"
        }
        return "\(host).amazonaws.com"
    }

}

private extension Dictionary where Key == String, Value == String {

    var amzSorted: [(key: String, value: String)] {
        return sorted(by: { a, b -> Bool in
            a.key < b.key
        })
    }

    var amzTimestamp: String {
        get {
            return self["x-amz-date"] ?? ""
        }
        set {
            self["x-amz-date"] = newValue
        }
    }

    var amzYMD: String {
        let timestamp = amzTimestamp
        return String(timestamp.index(of: "T").map { timestamp[..<$0] } ?? "")
    }

    var amzContentSha: String {
        get {
            return self["x-amz-content-sha256"] ?? ""
        }
        set {
            self["x-amz-content-sha256"] = newValue
        }
    }

}
