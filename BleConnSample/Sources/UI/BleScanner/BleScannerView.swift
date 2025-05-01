import SwiftUI
import BleConn

struct BleScannerView: View {
  @ObservedObject var viewModel: BleScannerViewModel

  var body: some View {
    VStack(spacing: 16) {
      Button(action: {
        viewModel.dispatch(action: .startScan)
      }) {
        Text("Start scan")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .disabled(viewModel.viewState.isScanning)
      .opacity(viewModel.viewState.isScanning ? 0.5 : 1.0)

      Button(action: {
        viewModel.dispatch(action: .stopScan)
      }) {
        Text("Stop scan")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .disabled(!viewModel.viewState.isScanning)
      .opacity(!viewModel.viewState.isScanning ? 0.5 : 1.0)
    }
    .padding(16)
    .frame(alignment: .top)
    .navigationTitle("BleScanner")
    .onDisappear {
      viewModel.dispatch(action: .stopScan)
    }
    
    List(viewModel.viewState.scanResults, id: \.peripheral.identifier) { scanResult in
      VStack(alignment: .leading, spacing: 8) {
        Text("Name: \(scanResult.peripheral.name ?? "Unknown")")
          .font(.headline)
        Text("RSSI: \(scanResult.rssi)")
          .font(.subheadline)
        Text("Manufacturer: \(scanResult.manufacturerInfo ?? "Unknown")")
          .font(.subheadline)
      }
      .padding()
      .cornerRadius(8)
    }
  }
}
