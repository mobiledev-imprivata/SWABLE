//
//  Peripheral.swift
//  SWABLE-Client
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import CoreBluetooth

protocol PeripheralDelegate: class {
    func peripheralDidStartAdvertising(_ peripheral: Peripheral)
    func peripheralDidStopAdvertising(_ peripheral: Peripheral)
}

final class Peripheral: NSObject {

    weak var delegate: PeripheralDelegate?

    private var service: CBMutableService = {
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
    private var servicesInitialized = false

    private var peripheralManager: CBPeripheralManager?

    func startAdvertising() {
        Message.post()

        guard peripheralManager == nil else {
            return
        }

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: Constants.Peripheral.identifier,
        ])
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

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        Message.post(dict)

        if let service = (dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService])?.first {
            self.service = service
            servicesInitialized = true
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Message.post(peripheral.state)

        if peripheral.state == .poweredOn {
            if servicesInitialized {
                if peripheral.isAdvertising {
                    delegate?.peripheralDidStartAdvertising(self)
                }
                else {
                    peripheral.startAdvertising([
                        CBAdvertisementDataServiceUUIDsKey: [service.uuid]
                    ])
                }
            }
            else {
                peripheral.removeAllServices()
                peripheral.add(service)
            }
        }
        else if peripheral.state == .poweredOff {
            stopAdvertising()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Message.post(service, error ?? "")

        servicesInitialized = true

        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        delegate?.peripheralDidStartAdvertising(self)
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
