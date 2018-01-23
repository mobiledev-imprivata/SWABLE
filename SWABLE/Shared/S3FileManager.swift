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
    private var securityPolicy: String? = Array("""
    """.utf8).toBase64()
    
    init() {
        
    }
    
    func upload(text: String) {
        let signDate = Date()
        let data = "Wow".data(using: .utf8)!
        let timestamp = S3FileManager.amazonDateFormatter.string(from: signDate)
        let contentSha: String = data.sha256().toHexString()
        
        let headers: HTTPHeaders = [
            "Host": bucketURL,
            "Content-Type": "text/plain",
            "x-amz-content-sha256": contentSha,
            "x-amz-date": timestamp,
            "Authorization": try! makeAuthorizationHeader(date: signDate, data: data)
        ]
        
        Alamofire.upload(data, to: "http://\(bucketURL)/text.txt", method: .put, headers: headers).responseString { (response) in
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
        
//        Alamofire.upload(data, to: "http://\(bucketURL)/text.txt", method: .put, headers: headers).responseString { (response) in
//            if let error = response.error, response.response?.statusCode == 400 {
//                print("Error: \(error.localizedDescription)")
//                print("Header: \(headers)")
//                print("Response: \(response)")
//            }
//            print("Response: \(response)")
//        }
    }
    
    func download() {
        
    }
    
    /// Value for the Authorization header in any requests this class makes to an S3 bucket.
    func makeAuthorizationHeader(date: Date, data: Data) throws -> String {
        
        guard let signature = try? createSignature(from: date, data: data) else {
            throw S3Error.RuntimeError("Could not create S3 signature!")
        }
        
        let yyyymmdd: String = S3FileManager.yyyymmddFormatter.string(from: date)
        
        return """
        AWS4-HMAC-SHA256 Credential=\(self.awsAccessKeyId)/\(yyyymmdd)/\(self.region)/\(self.service)/aws4_request,SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date,Signature=\(signature)
        """
        // AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41
        
    }
    
    func makeStringToSign(from date: Date, data: Data) -> String {
        let timestamp = S3FileManager.amazonDateFormatter.string(from: date)
        let yyyymmdd: String = S3FileManager.yyyymmddFormatter.string(from: date)
        let contentSha: String = data.sha256().toHexString()
        let canonicalRequest = """
        PUT
        /test.txt
        
        content-type:text/plain
        host:\(bucketURL)
        x-amz-content-sha256:\(contentSha)
        x-amz-date:\(timestamp)
        
        content-type;host;x-amz-content-sha256;x-amz-date
        \(contentSha)
        """
        
        return """
        AWS4-HMAC-SHA256
        \(timestamp)
        \(yyyymmdd)/\(self.region)/\(self.service)/aws4_request
        \(canonicalRequest.data(using: .utf8)!.sha256().toHexString())
        """
    }
    
    /*
     Creates the string for the Signature field of the Authorization header required for privileged access to S3 buckets.
     See https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
     */
    func createSignature(from date: Date, data: Data) throws -> String {
        
        let stringToSign = makeStringToSign(from: date, data: data)
        
        let formattedDate = S3FileManager.yyyymmddFormatter.string(from: date)
        
        let dateKey = try HMAC(key: "AWS4\(awsSecretAccessKey)", variant: .sha256).authenticate(formattedDate.utf8Array)
        let dateRegionKey = try HMAC(key: dateKey, variant: .sha256).authenticate(self.region.utf8Array)
        let dateRegionServiceKey = try HMAC(key: dateRegionKey, variant: .sha256).authenticate(self.service.utf8Array)
        let signingKey = try HMAC(key: dateRegionServiceKey, variant: .sha256).authenticate("aws4_request".utf8Array)
        
        let signature = try HMAC(key: signingKey, variant: .sha256).authenticate(Array(stringToSign.utf8))
        return signature.toHexString()
        
    }
    
    // Wed, 28 May 2014 19:31:11 +0000
    private static var headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    private static var yyyymmddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    /// Formats dates as ISO 8601 strings, for use with Amazon S3.
    private static var amazonDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.remove(.withColonSeparatorInTime)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
//        formatter.calendar = Calendar(identifier: .iso8601)
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }()
    
    
    
}

extension String {
    var utf8Array: Array<UInt8> {
        return Array(self.utf8)
    }
}
