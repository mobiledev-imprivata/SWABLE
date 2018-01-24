//
//  Peripheral.swift
//  SWABLE-Client
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CoreBluetooth

protocol PeripheralDelegate: class {
    func peripheralDidStartAdvertsising(_ peripheral: Peripheral)
    func peripheralDidStopAdvertising(_ peripheral: Peripheral)
}

final class Peripheral: NSObject {

    weak var delegate: PeripheralDelegate?

    private let service: CBMutableService = {
        let service = CBMutableService(
            type: CBUUID(string: Constants.Peripheral.service),
            primary: true
        )
        service.characteristics = [
            CBMutableCharacteristic(
                type: CBUUID(string: Constants.Peripheral.characteristic),
                properties: .read,
                value: nil,
                permissions: .readable
            )
        ]
        return service
    }()

    private var peripheralManager: CBPeripheralManager?

    func startAdvertising() {
        Message.post()

        guard peripheralManager == nil else {
            return
        }

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func stopAdvertising() {
        Message.post()

        guard let peripheralManager = peripheralManager else {
            return
        }

        peripheralManager.stopAdvertising()
        self.peripheralManager = nil

        delegate?.peripheralDidStopAdvertising(self)
    }

}

extension Peripheral: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Message.post(peripheral.state)

        if peripheral.state == .poweredOn {
            peripheral.removeAllServices()
            peripheral.add(service)
        }
        else if peripheral.state == .poweredOff {
            stopAdvertising()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Message.post(service, error ?? "")

        if error == nil {
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [service.uuid]
            ])
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Message.post(error ?? "")
        delegate?.peripheralDidStopAdvertising(self)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        Message.post(request)

        request.value = Constants.Peripheral.characteristicData
        peripheral.respond(to: request, withResult: .success)
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
