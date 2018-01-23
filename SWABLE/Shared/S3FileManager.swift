//
//  S3FileManager.swift
//  SWABLE
//
//  Created by Jonathan Cole on 1/22/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

/*
 Manages the process of uploading and downloading from an S3 bucket.
 */
import Foundation
import CryptoSwift
import Alamofire

class S3FileManager {
    
    enum S3Error: Error {
        case RuntimeError(String)
    }
    
    // Configuration for specific bucket
    private let bucketURL: String = "imprivata.raizlabs.xyz.s3.amazonaws.com"
    private let awsAccessKeyId: String = "AKIAJBGXVGYB3OGWCQFA"
    private let awsSecretAccessKey: String = "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"
    private let region = "us-east-1"
    private let service = "s3"
    
    func upload(text: String) {
        let signDate = Date()
        let data = "Wow".data(using: .utf8)!
        
        var headers: HTTPHeaders = [
            "Host": bucketURL,
        ]

        headers.amzTimestamp = S3FileManager.amazonDateFormatter.string(from: signDate)
        headers.amzContentSha = data.sha256().toHexString()

        if let additionalHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders {
            for header in additionalHeaders {
                headers[String(describing: header.key)] = String(describing: header.value)
            }
        }

        headers["Authorization"] = try? authorization(for: headers)

        Alamofire.upload(data, to: "http://\(bucketURL)/test.txt", method: .put, headers: headers).responseString { (response) in
            switch response.result {
            case .success(let value):
                print(value)
                break
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                print("Header: \(headers)")
                print("Response: \(response)")
                break
            }
        }
    }
    
    /// Value for the Authorization header in any requests this class makes to an S3 bucket.
    func authorization(for headers: HTTPHeaders) throws -> String {
        guard let signature = try? sign(headers) else {
            throw S3Error.RuntimeError("Could not create S3 signature!")
        }

        let headerKeys = headers.amzSorted.map { $0.key.lowercased() }.joined(separator: ";")

        return "AWS4-HMAC-SHA256 Credential=\(awsAccessKeyId)/\(headers.amzYMD)/\(region)/\(service)/aws4_request,SignedHeaders=\(headerKeys),Signature=\(signature)"
    }
    
    /*
     Creates the string for the Signature field of the Authorization header required for privileged access to S3 buckets.
     See https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
     */
    func sign(_ headers: HTTPHeaders) throws -> String {
        var canonicalRequest = """
        PUT
        /test.txt


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
        \(headers.amzYMD)/\(region)/\(service)/aws4_request
        \(canonicalRequest.data(using: .utf8)!.sha256().toHexString())
        """

        let dateKey = try HMAC(key: "AWS4\(awsSecretAccessKey)", variant: .sha256).authenticate(headers.amzYMD.bytes)
        let dateRegionKey = try HMAC(key: dateKey, variant: .sha256).authenticate(region.bytes)
        let dateRegionServiceKey = try HMAC(key: dateRegionKey, variant: .sha256).authenticate(service.bytes)
        let signingKey = try HMAC(key: dateRegionServiceKey, variant: .sha256).authenticate("aws4_request".bytes)

        return try HMAC(key: signingKey, variant: .sha256).authenticate(stringToSign.bytes).toHexString()
        
    }
    
    /// Formats dates as ISO 8601 strings, for use with Amazon S3.
    private static var amazonDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.remove(.withColonSeparatorInTime)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
        return formatter
    }()

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
