import CoreBluetooth
import SwiftUI
import BleConn

struct BleScannerView: View {
  @EnvironmentObject private var router: Router

  var body: some View {
    VStack {
      //        Button(state.isScanning ? "Stop Scanning" : "Start Scanning") {
      //          if state.isScanning {
      //            state.bleScanner.stop()
      //            state.isScanning = false
      //          } else {
      //            let started = state.bleScanner.start(
      //              filters: [CBUUID(string: "c27d7b88-26a5-4d6c-be82-7d7873dad979")],
      //              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true],
      //              onFound: { peripheral, advertisementData, rssi in
      //                print("Found device: \(peripheral.name ?? "Unknown") - RSSI: \(rssi)")
      //              },
      //              onError: { error in
      //                print("Error: \(error?.localizedDescription ?? "Unknown error")")
      //              }
      //            )
      //            state.isScanning = started
      //          }
      //        }
      //        .padding()
    }
    .navigationTitle("BleScanner")
  }
}
