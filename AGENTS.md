# BleConn iOS Project Guide

## Project Overview

BleConn is an iOS BLE (Bluetooth Low Energy) client library written in Swift. It wraps the CoreBluetooth framework and provides a clean API for BLE device scanning, connection, service discovery, and data read/write operations.

### Tech Stack

- **Language**: Swift 5.9
- **Platform**: iOS 16+
- **Dependency Management**: Swift Package Manager (SPM)
- **Core Framework**: CoreBluetooth
- **UI Framework**: SwiftUI (Sample App)
- **Architecture Pattern**: MVI (Model-View-Intent)
- **License**: Apache License 2.0

## Project Structure

```
bleconn-ios/
├── BleConn/                    # Core library source code
│   ├── BleConn.docc/           # Documentation directory
│   └── Sources/
│       ├── Client/
│       │   ├── BleClient.swift     # BLE client core class
│       │   ├── Results.swift       # Operation result type definitions
│       │   └── ScanResult.swift    # Scan result type
│       └── Utils/
│           ├── CallbackHolder.swift  # Callback timeout management utility
│           └── Logger/
│               ├── Logger.swift        # Logger protocol
│               └── DefaultLogger.swift # Default logger implementation
├── BleConn.xcodeproj/          # Xcode project file
├── BleConnSample/              # Sample application
│   └── Sources/
│       ├── BleConnSampleApp.swift   # App entry point
│       ├── Definitions/             # UUID and constant definitions
│       ├── DI/                      # Dependency injection
│       ├── Foundation/MVI/          # MVI architecture base
│       └── UI/                      # SwiftUI views
│           ├── BleScanner/          # Scanner view
│           ├── BleClient/           # Client view
│           ├── BleServer/           # Server view
│           └── Select/              # Selection page
├── BleConnTests/               # Library unit tests
├── BleConnSampleTests/         # Sample app tests
├── BleConnSampleUITests/       # UI tests
└── Package.swift               # SPM configuration file
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TW-Smart-CoE/bleconn-ios.git", from: "{TAG}")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/TW-Smart-CoE/bleconn-ios.git`
3. Select the version: `{TAG}`

## Building and Testing

### Building the Project

```bash
# Build using Swift Package Manager
swift build

# Or open the project in Xcode
open BleConn.xcodeproj
```

### Running Tests

```bash
# Run tests using Swift Package Manager
swift test

# Or run tests in Xcode: Cmd + U
```

### Using Xcode

1. Open `BleConn.xcodeproj`
2. Select a target device or simulator
3. Press `Cmd + B` to build the project
4. Press `Cmd + R` to run the sample app

## Core Library API

### BleClient Class

The main BLE client class implementing `CBCentralManagerDelegate` and `CBPeripheralDelegate`.

#### Initialization

```swift
// Using default configuration
let client = BleClient()

// Custom configuration
let client = BleClient(
    logger: customLogger,      // Custom logger
    connectTimeout: 5000,      // Connection timeout (milliseconds)
    requestTimeout: 3000,      // Request timeout (milliseconds)
    queue: customQueue         // Custom DispatchQueue
)
```

#### Scanning Devices

```swift
client.startScan(
    filters: [CBUUID],         // Optional service UUID filter
    options: [String: Any]?,   // Scan options
    onFound: { result in       // Device found callback
        // result.peripheral, result.rssi, result.advertisementData
    },
    onError: { error in }      // Error callback
)

client.stopScan()  // Stop scanning
```

#### Connecting to Devices

```swift
// Connect via CBPeripheral
client.connect(
    to: peripheral,
    onConnectStateChanged: { isConnected in },
    callback: { result in }
)

// Connect via UUID
client.connect(
    to: deviceUUID,
    onConnectStateChanged: { isConnected in },
    callback: { result in }
)

client.disconnect()  // Disconnect
```

#### Service Discovery

```swift
client.discoverServices(serviceUUIDs: [CBUUID]?) { result in
    if result.isSuccess {
        let services = result.services
    }
}
```

#### Reading/Writing Characteristics

```swift
// Read characteristic value
client.readCharacteristic(
    serviceUUID: serviceUUID,
    characteristicUUID: charUUID
) { result in
    if result.isSuccess {
        let data = result.value
    }
}

// Write characteristic value
client.writeCharacteristic(
    serviceUUID: serviceUUID,
    characteristicUUID: charUUID,
    value: data,
    type: .withResponse  // or .withoutResponse
) { result in }
```

### Result Types

- `Result` - Base result type with `isSuccess` and `errorMessage`
- `DiscoverServicesResult` - Service discovery result with `services` array
- `ReadResult` - Read result with `value` (Data)
- `ScanResult` - Scan result with `peripheral`, `rssi`, `advertisementData`

### Logger Protocol

```swift
public protocol Logger {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String)
    func fault(_ message: String)
}
```

Implement a custom logger and inject it into BleClient to customize logging behavior.

## Development Conventions

### Architecture Pattern

The sample app uses MVI (Model-View-Intent) architecture:

- **ViewState**: Struct defining view state
- **Action**: Enum defining user actions and events
- **ViewModel**: Implements `MVIViewModel` protocol with `reduce` and `runSideEffect` methods

```swift
// ViewModel example
class MyViewModel: MVIViewModel {
    @Published var viewState: MyState
    
    func reduce(currentState: MyState, action: MyAction) -> MyState {
        // Pure function state transformation
    }
    
    func runSideEffect(action: MyAction, currentState: MyState) {
        // Handle side effects (network requests, BLE operations, etc.)
    }
}
```

### Dependency Injection

The sample app uses protocol-based dependency abstraction:

```swift
protocol Dependency {
    var logger: Logger { get }
    var bleClient: BleClient { get }
}
```

### Logging Standards

- Use injected Logger protocol instead of `print`
- Log format: `{TAG} message`
- Log levels: `debug`, `info`, `error`, `fault`

### Error Handling

- All async operations return Result types via callbacks
- Result contains `isSuccess` boolean and `errorMessage` string
- Timeout mechanism managed automatically via `CallbackHolder`

## Common Tasks

### Adding a New BLE Operation

1. Add a public method in `BleClient.swift`
2. Create corresponding Result type if needed
3. Add CallbackHolder to manage callback
4. Implement CBPeripheralDelegate method to handle response

### Customizing Timeout Values

```swift
let client = BleClient(
    connectTimeout: 10000,  // 10 second connection timeout
    requestTimeout: 5000    // 5 second request timeout
)
```

### Using a Custom Queue

```swift
let bleQueue = DispatchQueue(label: "com.example.ble")
let client = BleClient(queue: bleQueue)
```

## Important Notes

- iOS does not require manual MTU requests; the system negotiates automatically
- BLE operations have timeout mechanisms: default 5 seconds for connection, 3 seconds for requests
- Connection state changes are notified via `onConnectStateChanged` callback
- `manufacturerData` in scan results can be used for device identification