//
//  Log.swift
//  SWABLE
//
//  Created by Jonathan Cole on 1/18/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation

/*
 Maintains a set of log messages.
 */
final class Log {
    
    var messages: [Message] = []

    /// Gives all the stored messages together as a string.
    var text: String {
        return messages.map { $0.description }.joined(separator: "\n")
    }
    
    /// Adds a new message to the log.
    func add(_ message: Message) {
        messages.append(message)
    }
    
}

// Upload functionality
extension Log {
    
    // Uploads all messages in the log as text to some service. Not sure which one yet.
    func upload() {
        let s3FileManager = S3FileManager(credentials: S3FileManager.Credentials(
            accessKey: "AKIAJBGXVGYB3OGWCQFA",
            secret: "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"
        ))

        s3FileManager.upload(text: text, to: S3FileManager.Bucket(
            name: "imprivata.raizlabs.xyz"
        ))
    }

}
