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

    private let textView = TextView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))

    override func loadView() {
        #if os(OSX)
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.minSize = textView.frame.size
            textView.maxSize = NSSize(width: .max, height: .max)
            textView.textContainerInset = NSSize(width: 5, height: 10)

            let scrollView = NSScrollView(frame: textView.frame)
            scrollView.documentView = textView

            view = scrollView
        #else
            view = textView
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.isEditable = false

        NotificationCenter.default.addObserver(self, selector: #selector(display), name: Message.notificationName, object: nil)
    }

    @objc private func display(notification: Notification) {
        guard let message = notification.userInfo?[Message.attributedTextKey] as? NSAttributedString else {
            return
        }

        DispatchQueue.main.async {
            self.append(attributedText: message)
        }
    }

    private func append(attributedText: NSAttributedString) {
        #if os(OSX)
            textView.textStorage?.append(NSMutableAttributedString(string: "\n"))
            textView.textStorage?.append(attributedText)
            textView.scrollRangeToVisible(NSRange(location: textView.textStorage?.length ?? 0, length: 0))
        #else
            let text = textView.attributedText.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString()
            text.append(NSMutableAttributedString(string: "\n"))
            text.append(attributedText)

            textView.attributedText = text
            textView.scrollRangeToVisible(NSRange(location: text.length, length: 0))
        #endif
    }

}