//
//  BleUUID.swift
//  BleConnSample
//
//  Created by Jie Meng on 2025/4/26.
//

import Foundation
import CoreBluetooth

struct BleUUID {
    static let SERVICE = CBUUID(string: "c27d7b88-26a5-4d6c-be82-7d7873dad979")
    static let SERVICE_NO_USE = CBUUID(string: "ac69a8b6-9505-49d8-ace0-492fd2228b55")
    static let CHARACTERISTIC_DEVICE_INFO = CBUUID(string: "5efe1dfb-f80a-411c-9a6b-41caf5ac6dba")
    static let CHARACTERISTIC_WIFI = CBUUID(string: "5cef40d1-c4c5-431c-b159-a7e895fce2bc")
    static let CHARACTERISTIC_DEVICE_STATUS = CBUUID(string: "55bedfda-55a9-4d2e-b2df-8d7e1ae3faf3")
    static let CHARACTERISTIC_PERF_TEST_READ = CBUUID(string: "44a66b15-32d9-401a-99d4-44132f07bfa1")
    static let CHARACTERISTIC_PERF_TEST_WRITE = CBUUID(string: "1b3dd8c9-aa8b-4de8-a6e6-def595d6b101")
}
