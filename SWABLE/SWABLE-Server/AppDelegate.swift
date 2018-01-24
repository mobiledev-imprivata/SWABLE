//
//  AppDelegate.swift
//  SWABLE-Server
//
//  Created by Rob Visentin on 1/16/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    private let beacon = Beacon()
    private let scanner = PeripheralScanner()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.contentViewController = LogViewController()
        window.makeFirstResponder(window.contentViewController)

        beacon.delegate = self
        scanner.delegate = self

        beacon.startAdvertising()
    }

}

extension AppDelegate: BeaconDelegate {

    func beaconDidStartAdvertising(_ beacon: Beacon) {
        Message.post()

        // Give peripheral some time to start advertising if it was woken up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.scanner.startScanning()
        }
    }

    func beaconDidStopAdvertising(_ beacon: Beacon) {
        Message.post()
    }

}

extension AppDelegate: PeripheralScannerDelegate {

    func peripheralScannerDidStartScanning(_ scanner: PeripheralScanner) {
        Message.post()
    }

    func peripheralScannerDidStopScanning(_ scanner: PeripheralScanner) {
        Message.post()
    }

    func peripheralScanner(_ scanner: PeripheralScanner, discovered peripheral: String, rssi: Int) {
        Message.post(peripheral, rssi)
    }

}
