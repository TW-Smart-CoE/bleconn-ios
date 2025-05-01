import Foundation
import Combine
import CoreBluetooth
import BleConn

class BleScannerViewModel: MVIViewModel {
  typealias S = BleScannerState
  typealias A = BleScannerAction

  @Published var viewState: BleScannerState
  private let bleScanner: BleScanner = .init()

  init(
    initialState: BleScannerState = BleScannerState(),
  ) {
    self.viewState = initialState
  }

  func reduce(currentState: BleScannerState, action: BleScannerAction) -> BleScannerState {
    var newState = currentState
    switch action {
    case let .onScanningStatusChanged(result):
      newState.isScanning = result
    case let .onFoundDevice(scanResult):
      newState.scanResults = buildNewScanResults(currentResults: currentState.scanResults, newResult: scanResult)
    default:
      break
    }

    return newState
  }

  func runSideEffect(action: BleScannerAction, currentState: BleScannerState) {
    switch action {
    case .startScan:
      startScan()
    case .stopScan:
      stopScan()
    default:
      break
    }
  }

  private func startScan() {
    let started = bleScanner.start(
      filters: [BleUUID.SERVICE],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true],
      onFound: { scanResult in
        let manufacturerData = scanResult.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let manufacturerInfo = manufacturerData?.map { String(format: "%02x", $0) }.joined() ?? "Unknown"
        print("Found device: \(scanResult.peripheral.name ?? "Unknown") - RSSI: \(scanResult.rssi) - Manufacturer: \(manufacturerInfo)")
        self.dispatch(action: .onFoundDevice(scanResult))
      },
      onError: { error in
        print("Error: \(error?.localizedDescription ?? "Unknown error")")
      }
    )
    dispatch(action: .onScanningStatusChanged(started))
  }

  private func stopScan() {
    guard viewState.isScanning else { return }
    bleScanner.stop()
    dispatch(action: .onScanningStatusChanged(false))
  }

  private func buildNewScanResults(currentResults: [ScanResult], newResult: ScanResult) -> [ScanResult] {
    var updatedResults = currentResults

    if let index = updatedResults.firstIndex(where: { existingResult in
      existingResult.peripheral.identifier == newResult.peripheral.identifier &&
      existingResult.manufacturerData == newResult.manufacturerData
    }) {
      updatedResults[index] = newResult
    } else {
      updatedResults.append(newResult)
    }

    return updatedResults
  }
}
