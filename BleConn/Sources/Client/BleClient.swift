import Foundation
import CoreBluetooth

public class BleClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private let TAG = "BleClient"

  private var logger: Logger = DefaultLogger()

  private var centralManager: CBCentralManager!
  private var connectedPeripheral: CBPeripheral?
  private var onConnectStateChanged: ((Bool) -> Void)?

  private var onFound: ((ScanResult) -> Void)?
  private var connectCallback: CallbackHolder<Result>
  private var discoverServicesCallback: CallbackHolder<DiscoverServicesResult>
  private var requestMtuCallback: CallbackHolder<MtuResult>
  private var readCallback: CallbackHolder<ReadResult>
  private var writeCallback: CallbackHolder<Result>

  private func initializeCentralManager(queue: DispatchQueue?) {
    centralManager = CBCentralManager(delegate: self, queue: queue)
  }

  public override init() {
    let connectTimeout = 5000
    let requestTimeout = 3000

    connectCallback = .init(timeout: TimeInterval(connectTimeout))
    discoverServicesCallback = .init(timeout: TimeInterval(requestTimeout))
    requestMtuCallback = .init(timeout: TimeInterval(requestTimeout))
    readCallback = .init(timeout: TimeInterval(requestTimeout))
    writeCallback = .init(timeout: TimeInterval(requestTimeout))

    super.init()
    initializeCentralManager(queue: nil)
  }

  public init(
    logger: Logger = DefaultLogger(),
    connectTimeout: TimeInterval = .init(5000),
    requestTimeout: TimeInterval = .init(3000),
    queue: DispatchQueue? = nil
  ) {
    self.logger = logger
    connectCallback = .init(timeout: connectTimeout)
    discoverServicesCallback = .init(timeout: requestTimeout)
    requestMtuCallback = .init(timeout: requestTimeout)
    readCallback = .init(timeout: requestTimeout)
    writeCallback = .init(timeout: requestTimeout)

    super.init()
    initializeCentralManager(queue: queue)
  }

  public func startScan(
    filters: [CBUUID]?,
    options: [String: Any]?,
    onFound: @escaping (ScanResult) -> Void,
    onError: (Error?) -> Void
  ) -> Bool {
    guard centralManager.state == .poweredOn else {
      onError(nil)
      return false
    }

    self.onFound = onFound
    centralManager.scanForPeripherals(withServices: filters, options: options)
    return true
  }

  public func stopScan() {
    guard centralManager.isScanning else { return }
    centralManager.stopScan()
    onFound = nil
  }

  public func connect(
    to device: CBPeripheral,
    onConnectStateChanged: @escaping (Bool) -> Void,
    callback: @escaping (Result) -> Void
  ) -> Bool {
    guard centralManager.state == .poweredOn else {
      let errorMessage = "Bluetooth is not enabled."
      logger.error(tag: TAG, message: errorMessage)

      return false
    }

    guard connectCallback.isSet() == false else {
      let errorMessage = "Another connection is in progress."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    self.onConnectStateChanged = onConnectStateChanged

    connectCallback.set(callback: callback)
    startCallbackCheckLoop()

    centralManager.connect(device, options: nil)

    return true
  }

  public func connect(
    to deviceId: UUID,
    onConnectStateChanged: @escaping (Bool) -> Void,
    callback: @escaping (Result) -> Void
  ) -> Bool {
    guard let device = centralManager.retrievePeripherals(withIdentifiers: [deviceId]).first else {
      let errorMessage = "Device not found."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    return connect(to: device, onConnectStateChanged: onConnectStateChanged, callback: callback)
  }

  public func disconnect() {
    if let peripheral = connectedPeripheral {
      centralManager.cancelPeripheralConnection(peripheral)
    }

    connectedPeripheral = nil
    onConnectStateChanged = nil
    logger.debug(tag: TAG, message: "Disconnected from peripheral.")
    stopCallbackCheckLoop()
  }

  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
    }
  }

  public func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    onFound?(.init(
      peripheral: peripheral,
      advertisementData: advertisementData,
      rssi: RSSI)
    )
  }

  public func readCharacteristic(
    serviceUUID: CBUUID,
    characteristicUUID: CBUUID,
    callback: @escaping (ReadResult) -> Void
  ) -> Bool {
    guard let connectedPeripheral = connectedPeripheral else {
      let errorMessage = "No connected peripheral."
      logger.error(tag: TAG, message: errorMessage)
      callback(ReadResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard !readCallback.isSet() else {
      let errorMessage = "Another read characteristic is in progress."
      logger.error(tag: TAG, message: errorMessage)
      callback(ReadResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard let service = connectedPeripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
      let errorMessage = "Service with UUID \(serviceUUID) not found."
      logger.error(tag: TAG, message: errorMessage)
      callback(ReadResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
      let errorMessage = "Characteristic with UUID \(characteristicUUID) not found."
      logger.error(tag: TAG, message: errorMessage)
      callback(ReadResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    readCallback.set(callback: callback)
    connectedPeripheral.readValue(for: characteristic)
    return true
  }

  public func writeCharacteristic(
    serviceUUID: CBUUID,
    characteristicUUID: CBUUID,
    value: Data,
    type: CBCharacteristicWriteType = .withResponse,
    callback: @escaping (Result) -> Void
  ) -> Bool {
    guard let connectedPeripheral = connectedPeripheral else {
      let errorMessage = "No connected peripheral."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard !writeCallback.isSet() else {
      let errorMessage = "Another write characteristic is in progress."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard let service = connectedPeripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
      let errorMessage = "Service with UUID \(serviceUUID) not found."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
      let errorMessage = "Characteristic with UUID \(characteristicUUID) not found."
      logger.error(tag: TAG, message: errorMessage)
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    writeCallback.set(callback: callback)
    connectedPeripheral.writeValue(value, for: characteristic, type: type)
    if type == .withoutResponse {
      writeCallback.resolve(result: Result(isSuccess: true))
    }

    return true
  }

  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
      let errorMessage = "Characteristic read failed: \(error.localizedDescription)"
      logger.error(tag: TAG, message: errorMessage)
      readCallback.resolve(result: ReadResult(isSuccess: false, errorMessage: errorMessage))
      return
    }

    guard let value = characteristic.value else {
      let errorMessage = "Characteristic value is nil."
      logger.error(tag: TAG, message: errorMessage)
      readCallback.resolve(result: ReadResult(isSuccess: false, errorMessage: errorMessage))
      return
    }

    logger.debug(tag: TAG, message: "Characteristic read successfully.")
    readCallback.resolve(result: ReadResult(isSuccess: true, value: value))
  }

  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
      let errorMessage = "Characteristic write failed: \(error.localizedDescription)"
      logger.error(tag: TAG, message: errorMessage)
      writeCallback.resolve(result: Result(isSuccess: false, errorMessage: errorMessage))
      return
    }
    logger.debug(tag: TAG, message: "Characteristic written successfully.")
    writeCallback.resolve(result: Result(isSuccess: true))
  }

  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    connectedPeripheral = peripheral
    connectedPeripheral?.delegate = self
    onConnectStateChanged?(true)
    connectCallback.resolve(result: Result(isSuccess: true))
  }

  public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    connectedPeripheral = nil
    onConnectStateChanged?(false)
    connectCallback.resolve(result: Result(isSuccess: false, errorMessage: error?.localizedDescription ?? ""))
  }

  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    onConnectStateChanged?(false)
    connectCallback.resolve(result: Result(isSuccess: false, errorMessage: error?.localizedDescription ?? ""))
  }

  public func discoverServices(serviceUUIDs: [CBUUID]?, callback: @escaping (DiscoverServicesResult) -> Void) -> Bool {
    guard let connectedPeripheral = connectedPeripheral else {
      let errorMessage = "No connected peripheral."
      logger.error(tag: TAG, message: errorMessage)
      callback(DiscoverServicesResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    guard !discoverServicesCallback.isSet() else {
      let errorMessage = "Another discover services is in progress."
      logger.error(tag: TAG, message: errorMessage)
      callback(DiscoverServicesResult(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    discoverServicesCallback.set(callback: callback)
    connectedPeripheral.discoverServices(serviceUUIDs)
    return true
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      let errorMessage = "Failed to discover services: \(error.localizedDescription)"
      logger.error(tag: TAG, message: errorMessage)
      discoverServicesCallback.resolve(result: DiscoverServicesResult(isSuccess: false, errorMessage: errorMessage))
      return
    }

    guard let services = peripheral.services else {
      let errorMessage = "No services found."
      logger.error(tag: TAG, message: errorMessage)
      discoverServicesCallback.resolve(result: DiscoverServicesResult(isSuccess: false, errorMessage: errorMessage))
      return
    }

    logger.debug(tag: TAG, message: "GATT services discovered.")
    services.forEach { service in
      logger.debug(tag: TAG, message: "Service: \(service.uuid)")
      peripheral.discoverCharacteristics(nil, for: service)
    }

    discoverServicesCallback.resolve(result: DiscoverServicesResult(isSuccess: true, services: services))
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let error = error {
      logger.error(tag: TAG, message: "Failed to discover characteristics: \(error.localizedDescription)")
      return
    }

    guard let characteristics = service.characteristics else {
      logger.debug(tag: TAG, message: "No characteristics found for service: \(service.uuid)")
      return
    }

    logger.debug(tag: TAG, message: "Characteristics discovered for service: \(service.uuid)")
    for characteristic in characteristics {
      logger.debug(tag: TAG, message: "Characteristic: \(characteristic.uuid)")
    }
  }

  private func startCallbackCheckLoop() {
  }

  private func stopCallbackCheckLoop() {
    logger.debug(tag: TAG, message: "stopCallbackCheckLoop")
  }
}
