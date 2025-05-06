import SwiftUI

struct SelectView: View {
  @EnvironmentObject var dependency: DependencyImpl
  @EnvironmentObject var router: Router
  @StateObject var viewModel: SelectViewModel

  init(dependency: Dependency, router: Router) {
    _viewModel = StateObject(wrappedValue: SelectViewModel(dependency: dependency, router: router))
  }

  var body: some View {
    NavigationStack(path: $router.path) {
      VStack(spacing: 16) {
        bleScanner
      }
      .padding(16)
      .frame(maxHeight: .infinity, alignment: .top)
      .navigationDestination(for: AppRoute.self) { route in
        destinationView(for: route)
      }
      .navigationTitle("BleConn")
    }
  }

  private func destinationView(for route: AppRoute) -> AnyView {
    switch route {
    case .bleScanner:
      return AnyView(BleScannerView(dependency: dependency, router: router))
    case .bleServer:
      return AnyView(BleServerView())
    case .bleClient(let peripheralId):
      return AnyView(BleClientView(dependency: dependency, peripheralId: peripheralId))
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
