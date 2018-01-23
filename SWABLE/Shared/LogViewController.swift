//
//  LogViewController.swift
//  SWABLE
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Anchorage

#if os(OSX)
    typealias ViewController = NSViewController
    typealias TextView = NSTextView
#else
    typealias ViewController = UIViewController
    typealias TextView = UITextView
#endif

final class LogViewController: ViewController {

    private let textView = TextView(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
    let log = MessageLog()

    override func loadView() {
        #if os(OSX)
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.minSize = textView.frame.size
            textView.maxSize = NSSize(width: .max, height: .max)
            textView.textContainerInset = NSSize(width: 5, height: 10)
            textView.autoresizingMask = .width

            let scrollView = NSScrollView(frame: textView.frame)
            scrollView.hasVerticalScroller = true
            scrollView.documentView = textView

            view = scrollView
        #else
            view = textView
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.isEditable = false

        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage), name: Message.notificationName, object: nil)
        
        log.upload()
    }

    @IBAction func clear(_ sender: Any) {
        #if os(OSX)
            textView.textStorage?.setAttributedString(NSAttributedString())
        #else
            textView.attributedText = nil
        #endif
    }

    @objc private func onReceiveMessage(notification: Notification) {
        guard let message = notification.userInfo?[Message.objectKey] as? Message else {
            return
        }
        
        // Add the message to the log
        log.add(message)
        
        // Display the message in the view
        DispatchQueue.main.async {
            self.append(message: message)
        }
    }

    private func append(message: Message) {
        #if os(OSX)
            textView.textStorage?.append(NSMutableAttributedString(string: "\n"))
            textView.textStorage?.append(message.attributedDescription)

            if textView.visibleRect.minY >= textView.bounds.height - textView.visibleRect.height {
                textView.scrollRangeToVisible(NSRange(location: textView.textStorage?.length ?? 0, length: 0))
            }
        #else
            let text = textView.attributedText.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString()
            text.append(NSMutableAttributedString(string: "\n"))
            text.append(message.attributedDescription)

            textView.attributedText = text
            textView.scrollRangeToVisible(NSRange(location: text.length, length: 0))
        #endif
    }

}
