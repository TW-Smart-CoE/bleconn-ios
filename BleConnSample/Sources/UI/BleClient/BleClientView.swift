import CoreBluetooth
import SwiftUI
import BleConn

struct BleClientView: View {
  @State private var isConnected: Bool = false
  @State private var mtu: Int = 0
  @State private var notification: String = ""

  var body: some View {
    VStack(spacing: 16) {
      Text("BleClient")
        .font(.title)
        .padding(.top, 8)

      Text("isConnected: \(isConnected)")
        .font(.subheadline)

      Text("MTU: \(mtu)")
        .font(.subheadline)

      Button(action: {
        // Discover services action
      }) {
        Text("Discover Services")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      HStack {
        TextField("Request MTU", value: $mtu, formatter: NumberFormatter())
          .textFieldStyle(.roundedBorder)
          .keyboardType(.numberPad)

        Button(action: {
          // Request MTU action
        }) {
          Text("Request MTU")
        }
        .buttonStyle(.borderedProminent)
      }

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

      Button(action: {
        // Enable notification action
      }) {
        Text("Enable Notification")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      Button(action: {
        // Disable notification action
      }) {
        Text("Disable Notification")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      Text("Notification: \(notification)")
        .font(.subheadline)

      Spacer()
    }
    .padding()
    .navigationTitle("BleClient")
  }
}
