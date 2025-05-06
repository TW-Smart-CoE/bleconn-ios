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

  private func initializeCentralManager(queue: DispatchQueue?) {
    centralManager = CBCentralManager(delegate: self, queue: queue)
  }

  public override init() {
    let connectTimeout = 5000
    let requestTimeout = 3000

    connectCallback = .init(timeout: TimeInterval(connectTimeout))
    discoverServicesCallback = .init(timeout: TimeInterval(requestTimeout))
    requestMtuCallback = .init(timeout: TimeInterval(requestTimeout))

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

  public func requestMtu(_ mtu: Int, callback: @escaping (MtuResult) -> Void) -> Bool {
     guard let connectedPeripheral = connectedPeripheral else {
       let errorMessage = "No connected peripheral."
       logger.error(tag: TAG, message: errorMessage)
       callback(MtuResult(isSuccess: false, errorMessage: errorMessage))
       return false
     }

     guard !requestMtuCallback.isSet() else {
       let errorMessage = "Another request MTU is in progress."
       logger.error(tag: TAG, message: errorMessage)
       callback(MtuResult(isSuccess: false, errorMessage: errorMessage))
       return false
     }

     requestMtuCallback.set(callback: callback)

//     connectedPeripheral.setNotifyValue(true, for: CBMutableCharacteristic()) // Placeholder for actual MTU request logic
//    connectedPeripheral.setNotifyValue(<#T##enabled: Bool##Bool#>, for: <#T##CBCharacteristic#>)

     // Simulate success for now
//     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//       self.requestMtuCallback.resolve(MtuResult(isSuccess: true, mtu: mtu))
//     }

     return true
   }

  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    connectedPeripheral = peripheral
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

  private func startCallbackCheckLoop() {
  }

  private func stopCallbackCheckLoop() {
    logger.debug(tag: TAG, message: "stopCallbackCheckLoop")
  }
}
