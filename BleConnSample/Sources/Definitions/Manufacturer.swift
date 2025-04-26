//
//  Manufacturer.swift
//  BleConnSample
//
//  Created by Jie Meng on 2025/4/26.
//

import Foundation

struct Manufacturer {
    static let ID: UInt16 = 0x1234
    static let data: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x00, 0x02]
    static let dataMask: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00]
}
