import Foundation
import CoreBluetooth

public class BleClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private let TAG = "BleClient"

  private var logger: Logger = DefaultLogger()

  private var centralManager: CBCentralManager!
  private var connectedPeripheral: CBPeripheral?
  private var onConnectStateChanged: ((Bool) -> Void)?

  // Identifier of the peripheral currently being connected. Distinct from
  // `connectedPeripheral` (which is set only after didConnect). Used to detect
  // and discard "ghost" didConnect callbacks that arrive after a timeout/cancel
  // and to support orderly switch-device behaviour on rapid re-taps.
  private var pendingConnectId: UUID?
  // Strong reference to the peripheral pending connection — without it ARC may
  // free the peripheral before we get a chance to cancel it on supersede.
  private var pendingConnectPeripheral: CBPeripheral?

  private var onFound: ((ScanResult) -> Void)?
  private var pendingScan: PendingScan?
  private var connectCallback: CallbackHolder<Result>
  private var discoverServicesCallback: CallbackHolder<DiscoverServicesResult>
  private var readCallback: CallbackHolder<ReadResult>
  private var writeCallback: CallbackHolder<Result>
  private var callbackCheckTimer: Timer?

  private func initializeCentralManager(queue: DispatchQueue?) {
    centralManager = CBCentralManager(delegate: self, queue: queue)
  }

  public override init() {
    // TimeInterval is in SECONDS. 5s/3s aligns with Android (5000ms/3000ms).
    let connectTimeout: TimeInterval = 5
    let requestTimeout: TimeInterval = 3
    connectCallback = CallbackHolder<Result>(timeout: connectTimeout)
    discoverServicesCallback = CallbackHolder<DiscoverServicesResult>(timeout: requestTimeout)
    readCallback = CallbackHolder<ReadResult>(timeout: requestTimeout)
    writeCallback = CallbackHolder<Result>(timeout: requestTimeout)
    super.init()
    initializeCentralManager(queue: nil)
  }

  public init(
    logger: Logger = DefaultLogger(),
    connectTimeout: TimeInterval = 5,
    requestTimeout: TimeInterval = 3,
    queue: DispatchQueue? = nil
  ) {
    self.logger = logger
    connectCallback = CallbackHolder<Result>(timeout: connectTimeout)
    discoverServicesCallback = CallbackHolder<DiscoverServicesResult>(timeout: requestTimeout)
    readCallback = CallbackHolder<ReadResult>(timeout: requestTimeout)
    writeCallback = CallbackHolder<Result>(timeout: requestTimeout)
    super.init()
    initializeCentralManager(queue: queue)
  }

  public func getCentralManagerState() -> CBManagerState {
    return centralManager.state
  }

  /// Synchronous check for whether the given peripheral is currently connected.
  /// Mirrors Android `BleClient.isConnected(address:)`.
  public func isConnected(deviceId: UUID) -> Bool {
    guard let peripheral = connectedPeripheral else { return false }
    return peripheral.identifier == deviceId && peripheral.state == .connected
  }

  public func startScan(
    filters: [CBUUID]?,
    options: [String: Any]?,
    onFound: @escaping (ScanResult) -> Void,
    onError: @escaping (Error?) -> Void
  ) -> Bool {
    guard centralManager.state == .poweredOn else {
      logger.debug(
        tag: TAG,
        message: "startScan: BLE not poweredOn (state=\(centralManager.state.debugName)), will retry when ready"
      )
      pendingScan = PendingScan(filters: filters, options: options, onFound: onFound, onError: onError)
      return false
    }

    self.onFound = onFound
    centralManager.scanForPeripherals(withServices: filters, options: options)
    return true
  }

  public func stopScan() {
    pendingScan = nil
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
      callback(Result(isSuccess: false, errorMessage: errorMessage))
      return false
    }

    // Reentrancy protection — addresses "rapid repeated tap freezes BLE until
    // the app is force-killed" reported on multiple iPhones.
    //
    // Three cases must be handled before issuing a fresh CoreBluetooth connect:
    //   (a) Same device already connected → idempotent success.
    //   (b) Same device connect in progress → merge: replace the callback,
    //       do NOT start a second CoreBluetooth connect (which would race).
    //   (c) Different device connected / connecting → tear the old one down
    //       cleanly first, otherwise we end up with stale `connectedPeripheral`
    //       state and a "ghost" pending CoreBluetooth connect that fires later
    //       and resurrects the wrong peripheral.

    // (a) Same device already fully connected.
    if let current = connectedPeripheral,
       current.identifier == device.identifier,
       current.state == .connected {
      logger.debug(tag: TAG, message: "connect: peripheral \(device.identifier) already connected, returning success")
      self.onConnectStateChanged = onConnectStateChanged
      callback(Result(isSuccess: true))
      return true
    }

    // (b) Same device connect already in progress — merge.
    if let pendingId = pendingConnectId, pendingId == device.identifier {
      logger.debug(tag: TAG, message: "connect: merging duplicate connect to \(device.identifier) in progress")
      self.onConnectStateChanged = onConnectStateChanged
      // Replace the pending callback so only the latest caller is notified.
      // The previous caller's callback is silently dropped — they were calling
      // for the same outcome anyway.
      connectCallback.set(callback: callback)
      return true
    }

    // (c) A different device is connected or connecting — tear down before
    //     we issue a new connect. This is the critical fix for the
    //     "ghost peripheral" CoreBluetooth race where a late didConnect for
    //     the previous peripheral would otherwise resurrect stale state.
    if connectedPeripheral != nil || pendingConnectId != nil {
      let supersededId = pendingConnectId ?? connectedPeripheral?.identifier
      logger.debug(
        tag: TAG,
        message: "connect: superseding existing connection (\(supersededId.map { "\($0)" } ?? "?")) for new target \(device.identifier)"
      )
      tearDownCurrentConnection(reason: "Superseded by new connect to \(device.identifier)")
    }

    pendingConnectId = device.identifier
    pendingConnectPeripheral = device
    self.onConnectStateChanged = onConnectStateChanged

    connectCallback.set(callback: callback)
    startCallbackCheckLoop()

    centralManager.connect(device, options: nil)

    return true
  }

  /// Tear down whatever the BleClient is currently doing (connected or
  /// pending) without firing user-facing "manual disconnect" semantics. Used
  /// to make `connect()` reentrant when the caller switches target device
  /// while a previous connect is still in flight or established.
  private func tearDownCurrentConnection(reason: String) {
    // Cancel a peripheral that's either fully connected or pending.
    if let p = pendingConnectPeripheral ?? connectedPeripheral {
      centralManager.cancelPeripheralConnection(p)
    }
    // Resolve everything that's hanging — caller will start fresh.
    clearPendingCallbacks(reason: reason)
    pendingConnectId = nil
    pendingConnectPeripheral = nil
    connectedPeripheral = nil
    onConnectStateChanged = nil
    stopCallbackCheckLoop()
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
    // Cancel whichever peripheral CoreBluetooth knows about — connected OR
    // pending. Without this, calling disconnect() while a connect is still
    // in flight leaves a "ghost" pending connect that may later fire
    // didConnect and resurrect stale state.
    if let p = connectedPeripheral ?? pendingConnectPeripheral {
      centralManager.cancelPeripheralConnection(p)
    }

    // Notify before clearing the handler so listeners can react to disconnect.
    onConnectStateChanged?(false)

    // Resolve any pending callbacks so callers don't hang waiting for a reply
    // CoreBluetooth will not deliver after a manual cancel.
    clearPendingCallbacks(reason: "Manually disconnected")

    connectedPeripheral = nil
    pendingConnectId = nil
    pendingConnectPeripheral = nil
    onConnectStateChanged = nil
    logger.debug(tag: TAG, message: "Disconnected from peripheral.")
    stopCallbackCheckLoop()
  }

  private func clearPendingCallbacks(reason: String) {
    if connectCallback.isSet() {
      connectCallback.resolve(result: Result(isSuccess: false, errorMessage: reason))
    }
    if discoverServicesCallback.isSet() {
      discoverServicesCallback.resolve(result: DiscoverServicesResult(isSuccess: false, errorMessage: reason))
    }
    if readCallback.isSet() {
      readCallback.resolve(result: ReadResult(isSuccess: false, errorMessage: reason))
    }
    if writeCallback.isSet() {
      writeCallback.resolve(result: Result(isSuccess: false, errorMessage: reason))
    }
  }

  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    logger.debug(tag: TAG, message: "centralManagerDidUpdateState: \(central.state.debugName)")

    if central.state == .poweredOn, let pending = pendingScan {
      pendingScan = nil
      logger.debug(tag: TAG, message: "Retrying pending scan after BLE poweredOn")
      self.onFound = pending.onFound
      centralManager.scanForPeripherals(withServices: pending.filters, options: pending.options)
    } else if central.state != .poweredOn, let pending = pendingScan {
      // BLE went to a non-recoverable terminal state — surface the error so the
      // caller doesn't sit waiting forever for poweredOn that won't come.
      if central.state == .unauthorized || central.state == .unsupported {
        pendingScan = nil
        pending.onError(nil)
      }
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
    // Defensive: discard "ghost" didConnect callbacks that arrive after a
    // disconnect()/timeout/supersede has already torn the request down.
    // Without this guard, CoreBluetooth occasionally delivers a successful
    // connect after we've cancelled, which would otherwise resurrect
    // `connectedPeripheral` into a state that the application has no
    // record of (the classic "BLE freezes until app is killed" path on
    // iPhone 13).
    guard pendingConnectId == peripheral.identifier else {
      logger.debug(
        tag: TAG,
        message: "didConnect: ignoring stale peripheral \(peripheral.identifier) (pending=\(pendingConnectId.map { "\($0)" } ?? "nil")); cancelling"
      )
      central.cancelPeripheralConnection(peripheral)
      return
    }
    pendingConnectId = nil
    pendingConnectPeripheral = nil
    connectedPeripheral = peripheral
    connectedPeripheral?.delegate = self
    onConnectStateChanged?(true)
    connectCallback.resolve(result: Result(isSuccess: true))
  }

  public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    let reason = error?.localizedDescription ?? "Disconnected"
    // Only fire upper-layer state change if the peripheral that disconnected
    // is actually the one we believed to be connected. A late didDisconnect
    // for a superseded peripheral must NOT poison the new connection's state.
    let isCurrent = connectedPeripheral?.identifier == peripheral.identifier ||
                    pendingConnectId == peripheral.identifier
    if isCurrent {
      connectedPeripheral = nil
      pendingConnectId = nil
      pendingConnectPeripheral = nil
      onConnectStateChanged?(false)
      // Resolve every pending request — read/write/discover would otherwise hang
      // until the timeout timer fires (or never, if the timer was stopped).
      clearPendingCallbacks(reason: reason)
      stopCallbackCheckLoop()
    } else {
      logger.debug(
        tag: TAG,
        message: "didDisconnect: ignoring stale peripheral \(peripheral.identifier) (current=\(connectedPeripheral?.identifier.uuidString ?? "nil"))"
      )
    }
  }

  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let reason = error?.localizedDescription ?? "Failed to connect"
    let isCurrent = pendingConnectId == peripheral.identifier
    if isCurrent {
      pendingConnectId = nil
      pendingConnectPeripheral = nil
      onConnectStateChanged?(false)
      clearPendingCallbacks(reason: reason)
      stopCallbackCheckLoop()
    } else {
      logger.debug(
        tag: TAG,
        message: "didFailToConnect: ignoring stale peripheral \(peripheral.identifier) (pending=\(pendingConnectId.map { "\($0)" } ?? "nil"))"
      )
    }
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
    logger.debug(tag: TAG, message: "startCallbackCheckLoop")
    callbackCheckTimer?.invalidate()
    callbackCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        if self.connectCallback.isTimeout() {
            self.logger.debug(tag: self.TAG, message: "Connect timeout")
            // Cancel CoreBluetooth's pending connect explicitly. Otherwise it
            // can deliver a late didConnect for the now-abandoned peripheral
            // — which `didConnect`'s ghost guard handles, but cancelling
            // proactively shortens the window and frees radio sooner.
            if let p = self.pendingConnectPeripheral {
                self.centralManager.cancelPeripheralConnection(p)
            }
            self.connectCallback.resolve(result: Result(isSuccess: false, errorMessage: "Connect timeout"))
            self.disconnect()
        }
        if self.discoverServicesCallback.isTimeout() {
            self.discoverServicesCallback.resolve(result: DiscoverServicesResult(isSuccess: false, errorMessage: "Discover services timeout"))
        }
        if self.readCallback.isTimeout() {
            self.readCallback.resolve(result: ReadResult(isSuccess: false, errorMessage: "Read characteristic timeout"))
        }
        if self.writeCallback.isTimeout() {
            self.writeCallback.resolve(result: Result(isSuccess: false, errorMessage: "Write characteristic timeout"))
        }
    }
  }

  private func stopCallbackCheckLoop() {
    logger.debug(tag: TAG, message: "stopCallbackCheckLoop")
    callbackCheckTimer?.invalidate()
    callbackCheckTimer = nil
  }
}

struct PendingScan {
  let filters: [CBUUID]?
  let options: [String: Any]?
  let onFound: (ScanResult) -> Void
  let onError: (Error?) -> Void
}

extension CBManagerState {
  public var debugName: String {
    switch self {
    case .unknown: return "unknown"
    case .resetting: return "resetting"
    case .unsupported: return "unsupported"
    case .unauthorized: return "unauthorized"
    case .poweredOff: return "poweredOff"
    case .poweredOn: return "poweredOn"
    @unknown default: return "unknown(\(rawValue))"
    }
  }
}
