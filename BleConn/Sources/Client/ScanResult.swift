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
