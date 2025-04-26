import Foundation
import CoreBluetooth
import BleConn

struct BleScannerState: ViewState {
  var isScanning: Bool = false
}

enum BleScannerAction: Action {
  case startScan
  case stopScan
  case onScanningStatusChanged(_ result: Bool)
  case onFoundDevice(_ scanResult: ScanResult)
  case onConnectToDevice(_ peripheral: CBPeripheral)
}
