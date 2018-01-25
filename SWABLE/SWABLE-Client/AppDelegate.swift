//
//  AppDelegate.swift
//  SWABLE-Client
//
//  Created by Rob Visentin on 1/16/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let beaconMonitor = BeaconMonitor()
    private let peripheral = Peripheral()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LogViewController()
        window?.makeKeyAndVisible()

        launch(options: launchOptions)

        return true
    }

    private func launch(options: [UIApplicationLaunchOptionsKey: Any]?) {
        Message.post(options ?? [:])

        peripheral.delegate = self
        peripheral.startAdvertising()

        beaconMonitor.delegate = self
        beaconMonitor.start()
    }

}

extension AppDelegate: BeaconMonitorDelegate {

    func beaconMonitorDidStart(_ beaconMonitor: BeaconMonitor) {
        Message.post()
    }

    func beaconMonitorDidStop(_ beaconMonitor: BeaconMonitor) {
        Message.post()
    }

}

extension AppDelegate: PeripheralDelegate {

    func peripheralDidStartAdvertising(_ peripheral: Peripheral) {
        Message.post()
    }

    func peripheralDidStopAdvertising(_ peripheral: Peripheral) {
        Message.post()
    }

}
