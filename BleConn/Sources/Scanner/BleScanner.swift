import CoreBluetooth

public struct ScanResult {
  public let peripheral: CBPeripheral
  public let advertisementData: [String: Any]
  public let rssi: NSNumber
}

extension ScanResult {
  public var manufacturerInfo: String? {
    guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
      return nil
    }
    return manufacturerData.map { String(format: "%02x", $0) }.joined()
  }

  public var manufacturerData: Data? {
    return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
  }
}

public class BleScanner: NSObject, CBCentralManagerDelegate {
  private var centralManager: CBCentralManager!
  private var isScanning = false
  private var onFound: ((ScanResult) -> Void)?
  private var onError: ((Error?) -> Void)?

  public override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  public func isStarted() -> Bool {
    return isScanning
  }

  public func start(
    filters: [CBUUID]?,
    options: [String: Any]?,
    onFound: @escaping (ScanResult) -> Void,
    onError: @escaping (Error?) -> Void
  ) -> Bool {
    guard centralManager.state == .poweredOn else {
      onError(nil) // Bluetooth is not enabled
      return false
    }

    self.onFound = onFound
    self.onError = onError
    centralManager.scanForPeripherals(withServices: filters, options: options)
    isScanning = true
    return true
  }

  public func stop() {
    guard isScanning else { return }
    centralManager.stopScan()
    isScanning = false
  }

  // MARK: - CBCentralManagerDelegate

  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      onError?(nil) // Handle Bluetooth not being enabled
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
}
