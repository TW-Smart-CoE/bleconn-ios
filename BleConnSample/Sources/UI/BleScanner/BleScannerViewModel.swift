import Foundation
import Combine
import CoreBluetooth
import BleConn

class BleScannerViewModel: MVIViewModel {
  typealias S = BleScannerState
  typealias A = BleScannerAction

  @Published var viewState: BleScannerState
  var router: Router
  private let bleScanner: BleScanner = .init()

  init(
    initialState: BleScannerState = BleScannerState(),
    router: Router
  ) {
    self.viewState = initialState
    self.router = router
  }

  func reduce(currentState: BleScannerState, action: BleScannerAction) -> BleScannerState {
    var newState = currentState
    switch action {
    case .startScan,
        .stopScan:
      break
    case let .onScanningStatusChanged(result):
      newState.isScanning = result
    }
    return newState
  }

  func runSideEffect(action: BleScannerAction, currentState: BleScannerState) {
    switch action {
    case .onScanningStatusChanged:
      break
    case .startScan:
      startScan()
    case .stopScan:
      stopScan()

    }
  }

  private func startScan() {
    let started = bleScanner.start(
      filters: [BleUUID.SERVICE],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true],
      onFound: { peripheral, advertisementData, rssi in
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let manufacturerInfo = manufacturerData?.map { String(format: "%02x", $0) }.joined() ?? "Unknown"
        print("Found device: \(peripheral.name ?? "Unknown") - RSSI: \(rssi) - Manufacturer: \(manufacturerInfo)")
      },
      onError: { error in
        print("Error: \(error?.localizedDescription ?? "Unknown error")")
      }
    )
    dispatch(action: .onScanningStatusChanged(started))
  }

  private func stopScan() {
    bleScanner.stop()
    dispatch(action: .onScanningStatusChanged(false))
  }
}
