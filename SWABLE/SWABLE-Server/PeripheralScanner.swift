//
//  PeripheralScanner.swift
//  SWABLE-Server
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CoreBluetooth

protocol PeripheralScannerDelegate: class {
    func peripheralScannerDidStartScanning(_ scanner: PeripheralScanner)
    func peripheralScannerDidStopScanning(_ scanner: PeripheralScanner)

    func peripheralScanner(_ scanner: PeripheralScanner, discovered peripheral: String, rssi: Int)
}

final class PeripheralScanner: NSObject {

    weak var delegate: PeripheralScannerDelegate?

    private let serviceUUID = CBUUID(string: Constants.Peripheral.service)

    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?

    private var peripheralCache = [CBPeripheral]()

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
            centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])
            delegate?.peripheralScannerDidStartScanning(self)

        case .unknown:
            deferredWork = startScanning

        default:
            Message.post("Scan failed because bluetooth is unvailable!")
        }
    }

    func stopScanning() {
        Message.post()

        guard centralManager.isScanning else {
            return
        }

        centralManager.stopScan()
        delegate?.peripheralScannerDidStopScanning(self)
    }

    private func report(peripheral: CBPeripheral, rssi: NSNumber) {
        delegate?.peripheralScanner(self, discovered: peripheral.identifier.uuidString, rssi: rssi.intValue)
    }

}

extension PeripheralScanner: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Message.post(central.state)

        if central.state == .poweredOn {
            deferredWork?()
        }

        deferredWork = nil
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // If we've already identified this as the correct peripheral, we're done
        if peripheral.identifier == discoveredPeripheral?.identifier {
            report(peripheral: peripheral, rssi: RSSI)
        }

        // If peripheral is advertising services, including the one we're looking for,
        // then we've found the right peripheral
        else if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], services.contains(serviceUUID), services.contains(serviceUUID) {
            discoveredPeripheral = peripheral
            report(peripheral: peripheral, rssi: RSSI)
        }

        // If *might* be possible that the peripheral is advertising services,
        // but the one we're looking for wasn't included. Check the discovered services.
        else if let services = peripheral.services {
            if services.contains(where: { $0.uuid == serviceUUID }) {
                discoveredPeripheral = peripheral
                report(peripheral: peripheral, rssi: RSSI)
            }
        }

        // Services are completely unknown to us, so we have to connect and discover them
        else if !peripheralCache.contains(peripheral) {
            peripheralCache.append(peripheral)
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([
            serviceUUID,
        ])
    }

}

extension PeripheralScanner: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Message.post(error ?? "")

        if let services = peripheral.services, services.contains(where: { $0.uuid == serviceUUID }) {
            discoveredPeripheral = peripheral
        }

        centralManager.cancelPeripheralConnection(peripheral)
    }

}
