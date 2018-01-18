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

        beacon.startAdvertising()
        scanner.scanContinuously(interval: 2)
    }

}

extension AppDelegate: BeaconDelegate {

    func beaconDidStartAdvertising(_ beacon: Beacon) {
        Message.post()
    }

    func beaconDidStopAdvertising(_ beacon: Beacon) {
        Message.post()
    }

}
