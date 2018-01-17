//
//  ViewController.swift
//  SWABLE-Client
//
//  Created by Rob Visentin on 1/16/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Anchorage

class ViewController: UIViewController {

    private let textView = UITextView()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        view.addSubview(textView)
        textView.edgeAnchors == view.edgeAnchors
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
        let text = textView.attributedText.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString()
        text.append(NSMutableAttributedString(string: "\n"))
        text.append(attributedText)

        textView.attributedText = text
        textView.scrollRangeToVisible(NSRange(location: attributedText.length, length: 0))
    }

}

