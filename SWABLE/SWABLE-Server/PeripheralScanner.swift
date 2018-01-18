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

    private var scanInterval: TimeInterval = 0
    private var deferredWork: (() -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    deinit {
        stopScanning()
    }

    func scan() {
        Message.post()

        guard !centralManager.isScanning else {
            return
        }

        switch centralManager.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [
                CBUUID(string: Constants.Peripheral.service)
            ], options: nil)

        case .unknown:
            deferredWork = scan

        default:
            Message.post("Scan failed because bluetooth is unvailable!")
        }
    }

    func scanContinuously(interval: TimeInterval) {
        Message.post(interval)

        scanInterval = interval
        scan()
    }

    func stopScanning() {
        Message.post()

        scanInterval = 0
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
        central.stopScan()
        Message.post(peripheral, "RSSI: \(RSSI)")

        if scanInterval > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + scanInterval) { [weak self] in
                if (self?.scanInterval ?? 0) > 0 {
                    self?.scan()
                }
            }
        }
    }

}
