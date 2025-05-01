import Foundation
import Combine
import CoreBluetooth
import BleConn

class BleScannerViewModel: MVIViewModel {
  typealias S = BleScannerState
  typealias A = BleScannerAction

  @Published var viewState: BleScannerState

  private let TAG = "BleScannerViewModel"

  private let logger: Logger
  private let router: Router
  private let bleClient: BleClient

  init(
    initialState: BleScannerState = BleScannerState(),
    dependency: Dependency
  ) {
    self.viewState = initialState
    self.logger = dependency.logger
    self.router = dependency.router
    self.bleClient = dependency.bleClient
  }

  func reduce(currentState: BleScannerState, action: BleScannerAction) -> BleScannerState {
    var newState = currentState
    switch action {
    case let .onScanningStatusChanged(result):
      newState.isScanning = result
      if !result {
        newState.scanResults = []
      }
    case let .onFoundDevice(scanResult):
      newState.scanResults = buildNewScanResults(currentResults: currentState.scanResults, newResult: scanResult)
    case .stopScan:
      newState.isScanning = false
      newState.scanResults = []
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
    case let .connectToDevice(peripheral):
      stopScan()
      logger.debug(tag: TAG, message: "Connecting to device: \(peripheral.name ?? "Unknown")")
      print("Current path: \(router.path)")
      router.navigate(to: AppRoute.bleClient)
    case .testClient:
      router.navigate(to: AppRoute.bleClient)
    default:
      break
    }
  }

  private func startScan() {
    let started = bleClient.startScan(
      filters: [BleUUID.SERVICE],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true],
      onFound: { scanResult in
        let manufacturerData = scanResult.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let manufacturerInfo = manufacturerData?.map { String(format: "%02x", $0) }.joined() ?? "Unknown"
        self.logger.debug(
          tag: self.TAG,
          message: "Found device: \(scanResult.peripheral.name ?? "Unknown") - RSSI: \(scanResult.rssi) - Manufacturer: \(manufacturerInfo)"
        )

        DispatchQueue.main.async {
          self.dispatch(action: .onFoundDevice(scanResult))
        }
      },
      onError: { error in
        DispatchQueue.main.async {
          self.logger.error(tag: self.TAG, message: "Error: \(error?.localizedDescription ?? "Unknown error")")
        }
      }
    )
    dispatch(action: .onScanningStatusChanged(started))
  }

  private func stopScan() {
    bleClient.stopScan()
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
