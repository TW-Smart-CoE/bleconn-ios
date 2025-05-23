import CoreBluetooth
import SwiftUI
import BleConn

struct BleClientView: View {
  @StateObject private var viewModel: BleClientViewModel

  init(dependency: Dependency, peripheralId: UUID) {
    _viewModel = StateObject(wrappedValue: BleClientViewModel(dependency: dependency, peripheralId: peripheralId))
  }

  var body: some View {
    VStack(spacing: 16) {
      Text("isConnected: \(viewModel.viewState.isConnected)")
        .font(.subheadline)

//      Text("MTU: \(viewModel.viewState.mtu)")
//        .font(.subheadline)

      discoverServicesButton
//      requestMtuView
      readDeviceInfoButton
      writeWiFiConfigButton

      Spacer()
    }
    .padding()
    .navigationTitle("BleClient")
    .onDisappear {
      viewModel.dispatch(action: .disconnect)
    }
    .overlay(
      VStack {
        Spacer()
        toastView
      }
    )
  }

  private var discoverServicesButton: some View {
    Button(action: {
      viewModel.dispatch(action: .discoverServices)
    }) {
      Text("Discover Services")
        .frame(maxWidth: .infinity)
        .padding()
    }
    .buttonStyle(.borderedProminent)
  }

  private var readDeviceInfoButton: some View {
    Button(action: {
      viewModel.dispatch(action: .readDeviceInfo)
    }) {
      Text("Read Device Info")
        .frame(maxWidth: .infinity)
        .padding()
    }
    .buttonStyle(.borderedProminent)
  }

  private var writeWiFiConfigButton: some View {
    Button(action: {
      viewModel.dispatch(action: .writeWiFiConfig(ssid: "ssid", password: "password"))
    }) {
      Text("Write WiFi Config")
        .frame(maxWidth: .infinity)
        .padding()
    }
    .buttonStyle(.borderedProminent)
  }

//  private var requestMtuView: some View {
//    HStack {
//      TextField("Request MTU", value: $viewModel.viewState.requestMtu, formatter: NumberFormatter())
//        .textFieldStyle(.roundedBorder)
//        .keyboardType(.numberPad)
//
//      Button(action: {
//      }) {
//        Text("Request MTU")
//          .padding()
//      }
//      .buttonStyle(.borderedProminent)
//    }
//  }

  private var toastView: some View {
    Group {
      if viewModel.viewState.toastData.isShow {
        Text(viewModel.viewState.toastData.message)
          .padding()
          .background(Color.black.opacity(0.8))
          .foregroundColor(.white)
          .cornerRadius(8)
          .transition(.opacity)
          .padding(.bottom, 40)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .animation(.easeInOut, value: viewModel.viewState.toastData.isShow)
  }
}
