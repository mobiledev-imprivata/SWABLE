//
//  SystemInfoTextView.swift
//  Parasite
//
//  Created by Jonathan Cole on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import UIKit

/*
 Special UITextView that populates itself with info from SystemKit.
 */
class SystemInfoTextView: UITextView {

    lazy private var system = System()
    
    lazy private var battery: Battery? = {
        var bt = Battery()
        if bt.open() != kIOReturnSuccess {
            return nil
        }
        return bt
    }()
    
    func update() {
        isEditable = false

        var textChunks: [String] = []
        
        // Add CPU usage info
        let cpuUsage = system.usageCPU()
        let counts = System.processCounts()
        
        textChunks.append("""
            -------------------
            CPU
            -------------------
            
            Thermal State: \(getThermalStateString())
            
            Logical Cores: \(System.logicalCores())
            System: \(Int(cpuUsage.system))%
            User: \(Int(cpuUsage.user))%
            Idle: \(Int(cpuUsage.idle))%
            
            Processes: \(counts.processCount)
            Threads: \(counts.threadCount)
            """)
        
        // Add memory usage info
        let memoryUsage = System.memoryUsage()
        
        textChunks.append("""
            -------------------
            Memory
            -------------------
            
            RAM Total: \(memoryUnit(System.physicalMemory()))
            RAM Free: \(memoryUnit(memoryUsage.free))
            RAM Used: \(memoryUnit(memoryUsage.active))
            """)
        
        // Add battery info
        if let battery = battery {
            textChunks.append("""
            -------------------
            Battery
            -------------------
            Charge: \(battery.charge())%
            \(battery.isACPowered() ? "Plugged in" : "Not plugged in") \(battery.isCharging() ? "(and charging)" : "")
            """)
        } else {
            textChunks.append("""
            -------------------
            Battery
            -------------------

            Not available!
            """)
        }
        
        // Write info to text field
        self.text = textChunks.joined(separator: "\n\n")
    }

}

// Status info methods (non-StatusKit)
extension SystemInfoTextView {
    
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
        }
        else {
            return nil
        }
    }
    
    /// Converts a given value in GB to a more reader-friendly format.
    func memoryUnit(_ value: Double) -> String {
        if value < 1.0 { return String(Int(value * 1000.0)) + "MB" }
        else           { return NSString(format:"%.2f", value) as String + "GB" }
    }
}

