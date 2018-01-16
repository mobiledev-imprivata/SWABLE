//
//  ViewController.swift
//  Parasite
//
//  Created by Jonathan Cole on 1/16/18.
//  Copyright © 2018 Jonathan Cole. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    var updateTimer: Timer!

    @IBOutlet weak var launchStressTestButton: UIButton!
    @IBOutlet weak var stressTestIndicatorLabel: UILabel!
    @IBOutlet weak var thermalsLabel: UILabel!
    @IBOutlet weak var memoryUsageLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        launchStressTestButton.layer.cornerRadius = 5.0
        launchStressTestButton.layer.borderColor = UIColor.white.cgColor
        launchStressTestButton.layer.borderWidth = 2.0
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.16, repeats: true, block: { (timer) in
            self.thermalsLabel.text = self.getThermalStateString()
            self.memoryUsageLabel.text = self.memoryUsageBytes().map { "\($0 / 1024 / 1024) MB" } ?? "Unknown"
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func DispatchStressThreads() {
        
        stressTestIndicatorLabel.isHidden = false
        
        let numCores = ProcessInfo.processInfo.processorCount
        print("Launching stress threads for \(numCores) cores.")
        for _ in 0 ..< numCores {
            DispatchQueue.global().async {
                self.StressThread()
            }
        }
    }
    
    /// Gives a CPU core a lot to do. Here we do some grammar substitutions.
    func StressThread() {
        // Generate the l-system grammar for a Koch snowflake.
        var tokenString = "F"
        while true {
            var newString = ""
            for char in tokenString {
                if char == "F" {
                    newString += "F+F--F+F"
                }
                else {
                    newString += "\(char)"
                }
            }
            
            tokenString = newString
        }
        
    }


}

extension ViewController {
    
    func getThermalStateString() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case ProcessInfo.ThermalState.critical:
            return "Critical"
        case ProcessInfo.ThermalState.serious:
            return "Serious"
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        default:
            return "Unknown"
        }
    }
    
    /*
     Adapted from https://stackoverflow.com/a/39048651
     Reports the amount of RAM used in bytes.
     */
    func memoryUsageBytes() -> UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
            //print("Memory in use (in bytes): \(info.resident_size)")
        }
        else {
            return nil
//            print("Error with task_info(): " +
//                (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
}

