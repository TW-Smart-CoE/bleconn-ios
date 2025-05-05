import SwiftUI

struct SelectView: View {
  @EnvironmentObject var dependency: DependencyImpl
  @EnvironmentObject var router: Router
  @ObservedObject var viewModel: SelectViewModel

  var body: some View {
    NavigationStack(path: $router.path) {
      VStack(spacing: 16) {
        bleScanner
      }
      .padding(16)
      .frame(maxHeight: .infinity, alignment: .top)
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .bleScanner:
          AnyView(BleScannerView(viewModel: .init(dependency: dependency, router: router)))
        case .bleServer:
          AnyView(BleServerView())
        case .bleClient(let peripheralId):
          AnyView(BleClientView(viewModel: .init(dependency: dependency, peripheralId: peripheralId)))
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
