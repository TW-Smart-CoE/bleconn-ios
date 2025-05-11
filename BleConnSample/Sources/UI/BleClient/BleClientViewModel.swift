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
        case let .showToast(isShow, message):
          newState.toastData = .init(isShow: isShow, message: message)
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
    case let .writeWiFiConfig(ssid, password):
      writeWifiInfo(ssid: ssid, password: password)
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
          self.showToast(message: message)
        } else {
          self.logger.error(tag: self.TAG, message: result.errorMessage)
          self.showToast(message: result.errorMessage)
        }
      }
    }

    logger.debug(tag: TAG, message: "readDeviceInfo bleClient.readCharacteristic result: \(result)")
  }

  private func writeWifiInfo(ssid: String, password: String) {
    let result = bleClient.writeCharacteristic(
      serviceUUID: BleUUID.SERVICE,
      characteristicUUID: BleUUID.CHARACTERISTIC_WIFI,
      value: "\(ssid);\(password)".data(using: .utf8) ?? Data(),
      type: .withResponse
    ) { result in
      DispatchQueue.main.async {
        if result.isSuccess {
          let message = "Write WiFi config successfully"
          self.logger.debug(tag: self.TAG, message: message)
          self.showToast(message: message)
        } else {
          self.logger.error(tag: self.TAG, message: result.errorMessage)
          self.showToast(message: result.errorMessage)
        }
      }
    }

    logger.debug(tag: TAG, message: "writeWifiInfo bleClient.writeCharacteristic result: \(result)")
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
          self.showToast(message: "Found \(result.services.count) services")
        }
      }

      logger.debug(tag: TAG, message: "discoverServices bleClient.discoverServices result: \(result)")
    } else {
      dispatch(action: .onServicesDiscovered(services: []))
    }
  }

  private func showToast(message: String, duration: Int = 2) {
    DispatchQueue.main.async {
      self.dispatch(action: BleClientAction.showToast(isShow: true, message: message))
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
        self.dispatch(action: BleClientAction.showToast(isShow: false, message: ""))
      }
    }
  }
}
