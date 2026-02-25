// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BleConn",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BleConn",
            targets: ["BleConn"]
        ),
    ],
    targets: [
        .target(
            name: "BleConn",
            path: "BleConn/Sources"
        ),
        .testTarget(
            name: "BleConnTests",
            dependencies: ["BleConn"],
            path: "BleConnTests"
        ),
    ]
)
