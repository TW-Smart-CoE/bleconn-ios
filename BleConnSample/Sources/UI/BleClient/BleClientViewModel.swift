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

    connectToPeripheral(peripheralId: peripheralId)
  }

  func reduce(currentState: BleClientState, action: BleClientAction) -> BleClientState {
    var newState = currentState
        switch action {
          case let .connectStatusChanged(isConnected):
            newState.isConnected = isConnected
//        case let .onScanningStatusChanged(result):
    //      newState.isScanning = result
    //      if !result {
    //        newState.scanResults = []
    //      }
    //    case let .onFoundDevice(scanResult):
    //      newState.scanResults = buildNewScanResults(currentResults: currentState.scanResults, newResult: scanResult)
    //    case .stopScan:
    //      newState.isScanning = false
    //      newState.scanResults = []
        default:
          break
        }

    return newState
  }

  func runSideEffect(action: BleClientAction, currentState: BleClientState) {
    switch action {
    case .disconnect:
      bleClient.disconnect()
    case let .connectStatusChanged(isConnected):
      discoverServices(isConnected: isConnected)
    case .discoverServices:
      discoverServices(isConnected: currentState.isConnected)
    case .readDeviceInfo:
      readDeviceInfo()
    default:
      break
    }
  }

  private func connectToPeripheral(peripheralId: UUID) {
    let result = bleClient.connect(
      to: peripheralId,
      onConnectStateChanged: { isConnected in
        DispatchQueue.main.async {
          self.dispatch(action: .connectStatusChanged(isConnected: isConnected))
        }
      },
      callback: { result in
        DispatchQueue.main.async {
          if result.isSuccess {
            self.logger.debug(tag: self.TAG, message: "Successfully connected to peripheral.")
          } else {
            self.logger.error(tag: self.TAG, message: "Failed to connect: \(result.errorMessage)")
          }
        }
      }
    )

    logger.debug(tag: TAG, message: "connectToPeripheral bleClient.connect result: \(result)")
  }

  private func readDeviceInfo() {
    let result = bleClient.readCharacteristic(
      serviceUUID: BleUUID.SERVICE,
      characteristicUUID: BleUUID.CHARACTERISTIC_DEVICE_INFO
    ) { result in
      DispatchQueue.main.async {
        if result.isSuccess {
          let message = "Device info: \(String(data: result.value, encoding: .utf8) ?? "")"
          self.logger.debug(tag: self.TAG, message: message)
          // sendEvent(BleClientEvent.ShowToast(message))
        } else {
          self.logger.error(tag: self.TAG, message: result.errorMessage)
          // sendEvent(BleClientEvent.ShowToast("Failed to read device info"))
        }
      }
    }

    logger.debug(tag: TAG, message: "readDeviceInfo bleClient.readCharacteristic result: \(result)")
  }

  private func discoverServices(isConnected: Bool) {
    if isConnected {
      let result = bleClient.discoverServices(serviceUUIDs: [BleUUID.SERVICE]) { result in
        DispatchQueue.main.async {
          if !result.isSuccess {
            self.logger.error(tag: self.TAG, message: result.errorMessage)
          }
          self.dispatch(action: .onServicesDiscovered(services: result.services.filter {
            $0.uuid == BleUUID.SERVICE
          }))
        }
      }

      logger.debug(tag: TAG, message: "discoverServices bleClient.discoverServices result: \(result)")
    } else {
      dispatch(action: .onServicesDiscovered(services: []))
    }
  }
}
