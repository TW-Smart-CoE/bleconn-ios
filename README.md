# BleConn

A lightweight iOS BLE (Bluetooth Low Energy) client library written in Swift.

## Features

- 🔍 BLE device scanning with customizable filters
- 🔌 Easy device connection management
- 📡 GATT service and characteristic discovery
- 📖 Read and write characteristic values
- ⏱️ Built-in timeout handling for all operations
- 📝 Customizable logging system
- 🎯 Clean, callback-based API

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add BleConn to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/TW-Smart-CoE/bleconn-ios.git", from: "{TAG}")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/TW-Smart-CoE/bleconn-ios.git`
3. Select the version and add to your target

## Usage

### Initialization

```swift
import BleConn

// Basic initialization
let bleClient = BleClient()

// With custom configuration
let bleClient = BleClient(
    logger: MyCustomLogger(),
    connectTimeout: 10000,  // milliseconds
    requestTimeout: 5000    // milliseconds
)
```

### Scanning for Devices

```swift
bleClient.startScan(
    filters: nil,  // Or specify service UUIDs: [CBUUID(string: "...")]
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
) { scanResult in
    print("Found: \(scanResult.peripheral.name ?? "Unknown")")
    print("RSSI: \(scanResult.rssi)")
    print("Manufacturer Data: \(scanResult.manufacturerInfo ?? "N/A")")
} onError: { error in
    print("Scan error: \(error?.localizedDescription ?? "Unknown")")
}

// Stop scanning when done
bleClient.stopScan()
```

### Connecting to a Device

```swift
bleClient.connect(
    to: peripheral,
    onConnectStateChanged: { isConnected in
        print("Connection state: \(isConnected ? "connected" : "disconnected")")
    }
) { result in
    if result.isSuccess {
        print("Connected successfully")
    } else {
        print("Connection failed: \(result.errorMessage)")
    }
}

// Disconnect when done
bleClient.disconnect()
```

### Discovering Services

```swift
bleClient.discoverServices(nil) { result in
    if result.isSuccess {
        for service in result.services {
            print("Service: \(service.uuid)")
        }
    } else {
        print("Discovery failed: \(result.errorMessage)")
    }
}
```

### Reading Characteristics

```swift
bleClient.readCharacteristic(
    serviceUUID: CBUUID(string: "your-service-uuid"),
    characteristicUUID: CBUUID(string: "your-characteristic-uuid")
) { result in
    if result.isSuccess {
        let data = result.value
        print("Read data: \(data.hexEncodedString())")
    } else {
        print("Read failed: \(result.errorMessage)")
    }
}
```

### Writing Characteristics

```swift
let data = "Hello".data(using: .utf8)!

bleClient.writeCharacteristic(
    serviceUUID: CBUUID(string: "your-service-uuid"),
    characteristicUUID: CBUUID(string: "your-characteristic-uuid"),
    value: data,
    type: .withResponse
) { result in
    if result.isSuccess {
        print("Write successful")
    } else {
        print("Write failed: \(result.errorMessage)")
    }
}
```

### Custom Logger

Implement the `Logger` protocol for custom logging:

```swift
class MyLogger: Logger {
    func debug(_ message: String) {
        print("[DEBUG] \(message)")
    }
    
    func info(_ message: String) {
        print("[INFO] \(message)")
    }
    
    func error(_ message: String) {
        print("[ERROR] \(message)")
    }
    
    func fault(_ message: String) {
        print("[FAULT] \(message)")
    }
}

let bleClient = BleClient(logger: MyLogger())
```

## Sample App

The repository includes a sample app demonstrating:

- Device scanning and listing
- Connection management
- Service/characteristic discovery
- Read/write operations

Open `BleConn.xcodeproj` and run the BleConnSample target to see it in action.

## API Reference

### BleClient

| Method | Description |
|--------|-------------|
| `startScan(filters:options:onFound:onError:)` | Start scanning for BLE devices |
| `stopScan()` | Stop scanning |
| `connect(to:onConnectStateChanged:callback:)` | Connect to a device |
| `disconnect()` | Disconnect from current device |
| `discoverServices(_:callback:)` | Discover GATT services |
| `readCharacteristic(serviceUUID:characteristicUUID:callback:)` | Read a characteristic value |
| `writeCharacteristic(serviceUUID:characteristicUUID:value:type:callback:)` | Write to a characteristic |

### Result Types

| Type | Properties |
|------|------------|
| `Result` | `isSuccess`, `errorMessage` |
| `DiscoverServicesResult` | `isSuccess`, `errorMessage`, `services` |
| `ReadResult` | `isSuccess`, `errorMessage`, `value` |
| `ScanResult` | `peripheral`, `rssi`, `advertisementData`, `manufacturerData`, `manufacturerInfo` |

## License

Apache License 2.0. See [LICENSE.md](LICENSE.md) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
