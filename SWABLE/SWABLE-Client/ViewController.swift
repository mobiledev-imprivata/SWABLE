//
//  ViewController.swift
//  SWABLE
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

        NotificationCenter.default.addObserver(self, selector: #selector(display), name: Message.notificationName, object: nil)
    }

    @objc private func display(notification: Notification) {
        guard let message = notification.userInfo?[Message.notificationMessageKey] as? String else {
            return
        }

        DispatchQueue.main.async {
            self.textView.text.append("\n \(message)")
            self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 0))
        }
    }

}

