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
            type: CBUUID(string: "3025E7A9-CC24-4B7C-B806-0F674D07E46C"),
            primary: true
        )
        service.characteristics = [
            CBMutableCharacteristic(
                type: CBUUID(string: "9476292B-5E5A-4CD4-BD3E-9B1E7B4DB12E"),
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

        request.value = "👋".data(using: .utf8)
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
