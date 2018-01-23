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
class MessageLog {
    
    var messages: [Message] = []
    var s3FileManager = S3FileManager()
    
    /// Adds a new message to the log.
    func add(_ message: Message) {
        messages.append(message)
    }
    
    /// Gives all the stored messages together as a string.
    func getFullText() -> String {
        return messages.map {
            return $0.description
        }.joined(separator: "\n")
    }
    
}

// Upload functionality
extension MessageLog {
    
    // Uploads all messages in the log as text to some service. Not sure which one yet.
    func upload() {
        let fullText = getFullText()
        print("Uploading text: \n\(fullText)")
        s3FileManager.upload(text: fullText)
    }

}
