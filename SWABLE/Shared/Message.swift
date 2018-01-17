//
//  Message.swift
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation

public struct Message {

    public static let notificationName = Notification.Name(rawValue: "com.raizlabs.swable.message")
    public static let notificationMessageKey = "com.raizlabs.swable.message"

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public static func post(_ message: @autoclosure () -> Any = "", file: String = #file, _ function: String = #function) {
        let timestamp = Message.dateFormatter.string(from: Date())
        let messageText = String(describing: message())
        var text = "[\(timestamp)] \(file.components(separatedBy: "/").last ?? "") \(function)"

        if !messageText.isEmpty {
            text += ": \(messageText)"
        }

        print(text)

        NotificationCenter.default.post(name: Message.notificationName, object: nil, userInfo: [
            Message.notificationMessageKey: text
        ])
    }

}
