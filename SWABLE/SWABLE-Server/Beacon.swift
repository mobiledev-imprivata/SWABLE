//
//  Beacon.swift
//  SWABLE-Server
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CoreBluetooth
import CoreLocation

protocol BeaconDelegate: class {
    func beaconDidStartAdvertising(_ beacon: Beacon)
    func beaconDidStopAdvertising(_ beacon: Beacon)
}

final class Beacon: NSObject {

    weak var delegate: BeaconDelegate?

    private var peripheralManager: CBPeripheralManager?

    func startAdvertising() {
        guard peripheralManager == nil else {
            return
        }

        Message.post()

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [
            CBPeripheralManagerOptionShowPowerAlertKey: true
        ])
    }

    func stopAdvertising() {
        guard let peripheralManager = peripheralManager else {
            return
        }

        Message.post()

        peripheralManager.stopAdvertising()
        self.peripheralManager = nil

        delegate?.beaconDidStopAdvertising(self)
    }

    private struct AdvertisementData {

        var proximityUUID: UUID
        var major: CLBeaconMajorValue
        var minor: CLBeaconMinorValue
        var rssiAt1m: Int8

        // Mimics the beacon advertising packet sent by iOS devices
        // Adapted from https://stackoverflow.com/questions/19410398/turn-macbook-into-ibeacon
        func toDict() -> [String: Any] {
            var buffer = [UInt8](repeating: 0, count: 21)

            (proximityUUID as NSUUID).getBytes(&buffer)

            buffer[16] = UInt8(bitPattern: Int8(major >> 8))
            buffer[17] = UInt8(bitPattern: Int8(major & 255))

            buffer[18] = UInt8(bitPattern: Int8(minor >> 8))
            buffer[19] = UInt8(bitPattern: Int8(minor & 255))

            buffer[20] = UInt8(bitPattern: rssiAt1m)

            return [
                "kCBAdvDataAppleBeaconKey": NSData(bytes: &buffer, length: buffer.count)
            ]
        }

    }

}

extension Beacon: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Message.post(peripheral.state)

        if ( peripheral.state == .poweredOn ) {
            peripheral.startAdvertising(
                AdvertisementData(
                    proximityUUID: Constants.Beacon.proximityUUID,
                    major: Constants.Beacon.major,
                    minor: Constants.Beacon.minor,
                    rssiAt1m: Constants.Beacon.rssiAt1m
                ).toDict()
            )
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Message.post(error ?? "")
        delegate?.beaconDidStartAdvertising(self)
    }

}

extension CBManagerState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Off"
        case .poweredOn: return "On"
        }
    }

}
