//
//  PeripheralScanner.swift
//  SWABLE-Server
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CoreBluetooth

final class PeripheralScanner: NSObject {

    private var centralManager: CBCentralManager!

    private var deferredWork: (() -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    deinit {
        stopScanning()
    }

    func startScanning() {
        Message.post()

        guard !centralManager.isScanning else {
            return
        }

        switch centralManager.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [
                CBUUID(string: Constants.Peripheral.service)
            ], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])

        case .unknown:
            deferredWork = startScanning

        default:
            Message.post("Scan failed because bluetooth is unvailable!")
        }
    }

    func stopScanning() {
        Message.post()
        centralManager.stopScan()
    }

}

extension PeripheralScanner: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Message.post(central.state)

        if central.state == .poweredOn {
            deferredWork?()
            deferredWork = nil
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Message.post(peripheral, "RSSI: \(RSSI)")
    }

}
