import CoreBluetooth
import SwiftUI
import BleConn

struct BleClientView: View {
  @ObservedObject var viewModel: BleClientViewModel

  var body: some View {
    VStack(spacing: 16) {
      Text("isConnected: \(viewModel.viewState.isConnected)")
        .font(.subheadline)

      Text("MTU: \(viewModel.viewState.mtu)")
        .font(.subheadline)

      Button(action: {
      }) {
        Text("Discover Services")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      requestMtuView

      Button(action: {
        // Read device info action
      }) {
        Text("Read Device Info")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      Button(action: {
        // Write WiFi config action
      }) {
        Text("Write WiFi Config")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationTitle("BleClient")
  }

  private var requestMtuView: some View {
    HStack {
      TextField("Request MTU", value: $viewModel.viewState.requestMtu, formatter: NumberFormatter())
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numberPad)

      Button(action: {
      }) {
        Text("Request MTU")
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
