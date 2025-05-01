import SwiftUI

struct SelectView: View {
  @EnvironmentObject var dependency: DependencyImpl
  @ObservedObject var viewModel: SelectViewModel

  var body: some View {
    NavigationStack(path: $dependency.router.path) {
      VStack(spacing: 16) {
        bleScanner
      }
      .padding(16)
      .frame(maxHeight: .infinity, alignment: .top)
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .bleScanner:
          AnyView(BleScannerView(viewModel: .init(dependency: dependency)))
        case .bleServer:
          AnyView(BleServerView())
        case .bleClient:
          AnyView(BleClientView())
        }
      }
      .navigationTitle("BleConn")
    }
  }

  private var bleServer: some View {
    Button(action: {
      viewModel.dispatch(action: .clickBleServer)
    }) {
      Text("BLE Server")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
  }

  private var bleScanner: some View {
    Button(action: {
      viewModel.dispatch(action: .clickBleScanner)
    }) {
      Text("BLE Scanner")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
  }
}
