//
//  BleScannerIntent.swift
//  BleConnSample
//
//  Created by Jie Meng on 2025/4/26.
//

import Foundation

struct BleScannerState: ViewState {
  var isScanning: Bool = false
}

enum BleScannerAction: Action {
  case startScan
  case stopScan
  case onScanningStatusChanged(_ result: Bool)
}
