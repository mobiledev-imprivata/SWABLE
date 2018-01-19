//
//  Message.swift
//  SWABLE
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

struct Message: CustomStringConvertible {

    public static let notificationName = Notification.Name(rawValue: "com.raizlabs.swable.message")
    public static let objectKey = "com.raizlabs.swable.messageObject"
    
    var text: String
    var date: Date
    var file: String
    var line: Int
    var function: String
    
    private init(text: String, date: Date, file: String, line: Int, function: String) {
        self.text = text
        self.date = date
        self.file = file
        self.line = line
        self.function = function
    }
    
    var description: String {
        let formattedDate = Message.dateFormatter.string(from: self.date)
        var finalString = "[\(formattedDate)] \(self.file) \(self.function)"
        
        if !text.isEmpty {
            finalString += ": \(self.text)"
        }
        
        return finalString
    }
    
    var attributedDescription: NSAttributedString {
        let formattedDate = Message.dateFormatter.string(from: self.date)
        
        let desc = self.description
        
        let attributedText = NSMutableAttributedString(string: desc, attributes: [
            .font: Font.systemFont(ofSize: 12)
            ])
        attributedText.addAttributes([
            //.font: Font.boldSystemFont(ofSize: 12)
            .font: Font.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
            ], range: (desc as NSString).range(of: formattedDate))

        
        return attributedText
    }

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    public static func post(_ messages: Any..., file: String = #file, _ function: String = #function, _ line: Int = #line) {
        let date = Date()
        let fileName = file.components(separatedBy: "/").last ?? ""
        let timestamp = "[\(Message.dateFormatter.string(from: date))]"
        let messageText = messages.map(String.init(describing:)).joined(separator: " ")
        var text = "\(timestamp) \(fileName) \(function)"
        
        if !messageText.isEmpty {
            text += ": \(messageText)"
        }
        
        let message = Message(text: messageText, date: date, file: fileName, line: line, function: function)
        
        NotificationCenter.default.post(name: Message.notificationName, object: nil, userInfo: [ Message.objectKey: message ])
    }
    
    

}
