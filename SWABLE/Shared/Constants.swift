//
//  Constants.swift
//  SWABLE
//
//  Created by Rob Visentin on 1/17/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation

struct Constants {

    struct Beacon {

        static let proximityUUID = UUID(uuidString: "0130C53E-97C1-421A-81C0-FC8F453295AD")!
        static let major: UInt16 = 0x01
        static let minor: UInt16 = 0x03
        static let identifier = "com.raizlabs.swable-server"
        static let rssiAt1m: Int8 = -56

    }

    struct Peripheral {

        static let identifier = "com.raizlabs.swable-client"
        static let service = "3025E7A9-CC24-4B7C-B806-0F674D07E46C"
        static let characteristic = "9476292B-5E5A-4CD4-BD3E-9B1E7B4DB12E"
        static let characteristicData = "👋".data(using: .utf8)

    }
    
}
