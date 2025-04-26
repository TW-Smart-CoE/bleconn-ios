import CoreBluetooth
import SwiftUI
import BleConn

struct BleScannerView: View {
  @EnvironmentObject private var router: Router
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
    .navigationTitle("BleScanner")
  }
}
