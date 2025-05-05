import Foundation
import Combine
import CoreBluetooth
import BleConn

class BleClientViewModel: MVIViewModel {
  typealias S = BleClientState
  typealias A = BleClientAction

  @Published var viewState: BleClientState

  private let TAG = "BleClientViewModel"

  private let logger: Logger
  private let bleClient: BleClient

  init(
    initialState: BleClientState = BleClientState(),
    dependency: Dependency,
    peripheralId: UUID,
  ) {
    self.viewState = initialState
    self.logger = dependency.logger
    self.bleClient = dependency.bleClient
  }

  func reduce(currentState: BleClientState, action: BleClientAction) -> BleClientState {
    var newState = currentState
    //    switch action {
    //    case let .onScanningStatusChanged(result):
    //      newState.isScanning = result
    //      if !result {
    //        newState.scanResults = []
    //      }
    //    case let .onFoundDevice(scanResult):
    //      newState.scanResults = buildNewScanResults(currentResults: currentState.scanResults, newResult: scanResult)
    //    case .stopScan:
    //      newState.isScanning = false
    //      newState.scanResults = []
    //    default:
    //      break
    //    }

    return newState
  }

  func runSideEffect(action: BleClientAction, currentState: BleClientState) {
  }
}
