//
//  ViewController.swift
//  Parasite
//
//  Created by Jonathan Cole on 1/16/18.
//  Copyright © 2018 Jonathan Cole. All rights reserved.
//

import UIKit
import Foundation
import Anchorage

class ViewController: UIViewController {
    
    private weak var updateTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }

    var launchStressTestButton = UIButton()
    let stressTestIndicatorLabel = UILabel()
    let textField = SystemInfoTextView()
    
    let healthyColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    let stressColor: UIColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    
    var workGroup: DispatchGroup = DispatchGroup()
    var workItems: [DispatchWorkItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUIElements()
        
        // Register a 60 Hz timer for updating the labels in the controller.
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] (timer) in
            self?.onTimerUpdate()
        }
        RunLoop.main.add(timer, forMode: .commonModes)
        updateTimer = timer
        
        // Update the system info view once to purge incorrect values at startup
        textField.update()
    }
    
    func createUIElements() {
        view.backgroundColor = healthyColor
        
        // Configure UI elements
        launchStressTestButton.setTitle("💀 Engage Stress 💀", for: .normal)
        launchStressTestButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        launchStressTestButton.layer.cornerRadius = 5.0
        launchStressTestButton.layer.borderColor = UIColor.white.cgColor
        launchStressTestButton.layer.borderWidth = 3.0
        launchStressTestButton.setTitleColor(.white, for: .normal)
        launchStressTestButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        view.addSubview(launchStressTestButton)
        launchStressTestButton.centerXAnchor == view.centerXAnchor
        launchStressTestButton.centerYAnchor == view.centerYAnchor * 0.25
        launchStressTestButton.addTarget(self, action: #selector(onStressButtonPressed), for: .touchUpInside)
        
        textField.isScrollEnabled = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(textField)
        textField.topAnchor == launchStressTestButton.bottomAnchor + 8
        textField.leftAnchor == view.leftAnchor + 48
        textField.rightAnchor == view.rightAnchor - 48
        
        stressTestIndicatorLabel.text = "STRESS ENGAGED"
        stressTestIndicatorLabel.textColor = .white
        stressTestIndicatorLabel.font = UIFont.boldSystemFont(ofSize: 24)
        view.addSubview(stressTestIndicatorLabel)
        stressTestIndicatorLabel.centerXAnchor == launchStressTestButton.centerXAnchor
        stressTestIndicatorLabel.centerYAnchor == launchStressTestButton.centerYAnchor
        stressTestIndicatorLabel.isHidden = true
    }
    
    /// Timer-managed update. Automatically called.
    private func onTimerUpdate() {
        textField.update()
        
        // Cancel all the stress threads if memory available gets too low.
        let memoryUsage = System.memoryUsage()
        if memoryUsage.free < 0.025 { // 50 MB
            for item in workItems {
                item.cancel()
            }
        }
        
    }
    
    @objc func onStressButtonPressed() {
        
        dispatchStressThreads()
        
        // Animate a transition from the "healthy" look to the "stressed" look.
        UIView.animate(withDuration: 0.2, animations: {
            self.launchStressTestButton.alpha = 0
        }) { (finished) in
            self.launchStressTestButton.isHidden = true
            
            self.stressTestIndicatorLabel.alpha = 0
            self.stressTestIndicatorLabel.isHidden = false
            UIView.animate(withDuration: 0.5) {
                self.stressTestIndicatorLabel.alpha = 1
                self.view.backgroundColor = self.stressColor
            }
        }
        
    }
    
    /*
     Enqueues `n` work items that greatly tax the hardware, where `n`
     is the number of logical cores in the CPU.
     
     The DispatchGroup managing these work items will relaunch its threads
     when they all end.
     */
    func dispatchStressThreads() {
        
        let numCores = System.logicalCores()
        print("Launching stress threads for \(numCores) cores.")
        for _ in 0 ..< numCores {
            // This smells bad, but I'm not sure how else to make a group of workItems with arbitrary length
            // and allow the workItems to monitor themselves for cancellation status.
            var workItem: DispatchWorkItem!
            workItem = DispatchWorkItem {
                // Gives a CPU core a lot to do. Here we do some grammar substitutions.
                // Ideally, we'd want to use some algorithm with very high (constant) space
                // and time complexity.
                var tokenString = "F"
                while !workItem.isCancelled {
                    tokenString = Array(tokenString).map {
                        return $0 == "F" ? "F+F--F+F" : "\($0)"
                        }.joined()
                }
                
                //print("Terminated stress thread.")
            }
            
            // Put the work item in the dispatch group and add it to our array
            // so we can reference it for cancellation later
            DispatchQueue.global().async(group: workGroup, execute: workItem)
            workItems.append(workItem)
        }
        
        workGroup.notify(queue: DispatchQueue.main) { [weak self] in
            print("All stress threads terminated.")
            if let weakSelf = self {
                weakSelf.workItems.removeAll()
                
                // Launch all the threads again.
                weakSelf.dispatchStressThreads()
            }
        }
        
    }

}

