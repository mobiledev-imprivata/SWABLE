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
    func peripheralScanner(_ scanner: PeripheralScanner, lost peripheral: String)
}

final class PeripheralScanner: NSObject {

    fileprivate(set) var isScanning = false

    weak var delegate: PeripheralScannerDelegate?

    private let scanWindow: TimeInterval = 2
    private let keepAliveInterval: TimeInterval = 10
    private let serviceUUID = CBUUID(string: Constants.Peripheral.service)

    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?

    private var advertisements = [PeripheralAdvertisement]()

    private weak var scanTimer: Timer?
    private weak var keepAliveTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    deinit {
        stopScanning()
    }

    func startScanning() {
        guard !isScanning else {
            return
        }

        Message.post()

        isScanning = true

        if centralManager.state == .poweredOn {
            startScanning(window: scanWindow)
            delegate?.peripheralScannerDidStartScanning(self)
        }
    }

    func stopScanning() {
        guard isScanning else {
            return
        }

        Message.post()

        centralManager.stopScan()

        scanTimer?.invalidate()
        keepAliveTimer?.invalidate()

        isScanning = false

        delegate?.peripheralScannerDidStopScanning(self)
    }

}

extension PeripheralScanner: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Message.post(central.state)

        if central.state == .poweredOn && isScanning {
            startScanning(window: scanWindow)
            delegate?.peripheralScannerDidStartScanning(self)
        }
        else if central.state == .poweredOff {
            scanTimer?.invalidate()
            keepAliveTimer?.invalidate()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Device must be connectable
        guard advertisementData[CBAdvertisementDataIsConnectable] as? Bool == true else {
            return
        }

        // Only consider devices above a certain signal threshold
        // NOTE: This matches Imprivata OneSign agent according to Paul
        guard RSSI.intValue > -85 else {
            return
        }

        advertisements.append(PeripheralAdvertisement(
            peripheral: peripheral,
            rssi: RSSI.intValue)
        )
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Message.post(peripheral.identifier.uuidString, error ?? "")
        connect(to: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Message.post(peripheral.identifier.uuidString)

        // Cancel timeout
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Message.post(peripheral.identifier.uuidString, error ?? "")

        // Cancel timeout
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        if peripheral.identifier == discoveredPeripheral?.identifier {
            discoveredPeripheral = nil
            keepAliveTimer?.invalidate()

            delegate?.peripheralScanner(self, lost: peripheral.identifier.uuidString)
        }

        // Can finally release reference to the pending peripheral
        _ = advertisements.popLast()

        respondToNextAdvertisement()
    }

}

extension PeripheralScanner: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Message.post(peripheral.services ?? [])
        if let services = peripheral.services, let serviceIndex = services.index(where: { $0.uuid == serviceUUID }) {
            Message.post("Found matching service")

            // We've found the right device
            discoveredPeripheral = peripheral

            // Clear other pending advertisements
            advertisements.removeAll()

            // Start reading from the connection
            peripheral.readRSSI()
            peripheral.discoverCharacteristics(nil, for: services[serviceIndex])
        }
        else {
            Message.post("No matching service")
            cancelConnection(to: peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Message.post(peripheral.identifier.uuidString)

        // Rediscover services
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) {
            guard let characteristic = service.characteristics?.first else {
                Message.post("WARNING: Service doesn't contain a characteristic!")
                return
            }

            let timer = Timer(timeInterval: keepAliveInterval, repeats: true) { _ in
                peripheral.readValue(for: characteristic)
            }
            RunLoop.main.add(timer, forMode: .commonModes)
            keepAliveTimer = timer
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        report(peripheral: peripheral, rssi: RSSI)
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Message.post("Heartbeat", characteristic.value.flatMap { String(data: $0, encoding: .utf8) } ?? "")
    }

}

// MARK: - Private

private extension PeripheralScanner {

    func startScanning(window: TimeInterval) {
        assert(window > 0)

        Message.post(window)

        // Have to discover *all* peripherals,
        // because service uuid is stripped from advertisising back while backgrounded
        centralManager.scanForPeripherals(withServices: nil, options: nil)

        // Schedule processing of peripherals discovered during the window
        let timer = Timer(timeInterval: window, repeats: false) { [weak self] _ in
            self?.processPeripherals()
        }
        RunLoop.main.add(timer, forMode: .commonModes)
        scanTimer = timer
    }

    func processPeripherals() {
        Message.post("Found", advertisements.count)

        // Scan will resume if we didn't find the device this time
        centralManager.stopScan()
        scanTimer?.invalidate()

        // Sort devices by signal strength (ascending)
        // The array will be proccesed in reverse order to take advantage of removeLast
        advertisements = advertisements.sorted { a, b -> Bool in
            a.rssi < b.rssi
        }

        respondToNextAdvertisement()
    }

    func respondToNextAdvertisement() {
        if let advertisement = advertisements.last {
            // Try the device with highest signal
            respond(to: advertisement)
        }
        else if !centralManager.isScanning {
            // Nothing found, repeat the scan
            startScanning(window: scanWindow)
        }
    }

    func respond(to advertisement: PeripheralAdvertisement) {
        connect(to: advertisement.peripheral)
    }

    func connect(to peripheral: CBPeripheral) {
        Message.post(peripheral.identifier.uuidString)
        centralManager.connect(peripheral, options: nil)

        // There is no built-in timeout, so skip the connection if it doesn't succeeed quickly
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(cancelConnection), with: peripheral, afterDelay: 2)
    }

    @objc func cancelConnection(to peripheral: CBPeripheral) {
        Message.post(peripheral.identifier.uuidString)

        let timeout = (peripheral.state == .connecting)

        centralManager.cancelPeripheralConnection(peripheral)

        if timeout {
            // Skip this peripheral, it's not behaving
            _ = advertisements.popLast()

            respondToNextAdvertisement()
        }
    }

    func report(peripheral: CBPeripheral, rssi: NSNumber) {
        delegate?.peripheralScanner(self, discovered: peripheral.identifier.uuidString, rssi: rssi.intValue)
    }

}

private struct PeripheralAdvertisement {

    var peripheral: CBPeripheral
    var rssi: Int

}
