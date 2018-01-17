//
//  BeaconMonitor.swift
//  SWABLE-Client
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation
import CoreLocation

protocol BeaconMonitorDelegate: class {
    func beaconMonitorDidStart(_ beaconMonitor: BeaconMonitor)
    func beaconMonitorDidStop(_ beaconMonitor: BeaconMonitor)
}

final class BeaconMonitor: NSObject {

    weak var delegate: BeaconMonitorDelegate?

    private let beaconRegion = CLBeaconRegion(
        proximityUUID: UUID(uuidString: "0130C53E-97C1-421A-81C0-FC8F453295AD")!,
        major: 123,
        minor: 456,
        identifier: "com.raizlabs.swable-server"
    )

    private var locationManager: CLLocationManager?

    func start() {
        Message.post()

        guard locationManager == nil else {
            return
        }

        guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
            Message.post("Beacon region monitoring isn't available!")
            return
        }

        locationManager = {
            $0.delegate = self
            $0.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            $0.pausesLocationUpdatesAutomatically = false
            $0.allowsBackgroundLocationUpdates = true
            $0.requestAlwaysAuthorization()
            return $0
        } (CLLocationManager())
    }

    func stop() {
        Message.post()

        guard let locationManager = locationManager else {
            return
        }

        locationManager.stopMonitoring(for: beaconRegion)
        self.locationManager = nil

        delegate?.beaconMonitorDidStop(self)
    }

}

extension BeaconMonitor: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Message.post(status)

        if status == .authorizedAlways {
            manager.startMonitoring(for: beaconRegion)
        }
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        Message.post()
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        Message.post()
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Message.post(region)
        delegate?.beaconMonitorDidStart(self)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Message.post(region)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Message.post(region)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Message.post(error)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Message.post(error)
    }

}

extension CLAuthorizationStatus: CustomStringConvertible {

    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When in Use"
        }
    }

}
