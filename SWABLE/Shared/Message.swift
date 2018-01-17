//
//  Message.swift
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

#if os(OSX)
    import AppKit
    private typealias Font = NSFont
#else
    import UIKit
    private typealias Font = UIFont
#endif

public struct Message {

    public static let notificationName = Notification.Name(rawValue: "com.raizlabs.swable.message")
    public static let textKey = "com.raizlabs.swable.message"
    public static let attributedTextKey = "com.raizlabs.swable.attributedMessage"

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public static func post(_ messages: Any..., file: String = #file, _ function: String = #function) {
        let timestamp = "[\(Message.dateFormatter.string(from: Date()))]"
        let messageText = messages.map(String.init(describing:)).joined(separator: " ")
        var text = "\(timestamp) \(file.components(separatedBy: "/").last ?? "") \(function)"

        if !messageText.isEmpty {
            text += ": \(messageText)"
        }

        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: Font.systemFont(ofSize: 12)
        ])
        attributedText.addAttributes([
            .font: Font.boldSystemFont(ofSize: 12)
        ], range: (text as NSString).range(of: timestamp))

        print(text)

        NotificationCenter.default.post(name: Message.notificationName, object: nil, userInfo: [
            Message.textKey: text,
            Message.attributedTextKey: attributedText,
        ])
    }

}
