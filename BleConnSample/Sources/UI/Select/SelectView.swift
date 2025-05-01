import SwiftUI

struct SelectView: View {
  @ObservedObject var viewModel: SelectViewModel

  var body: some View {
    NavigationStack(path: $viewModel.router.path) {
      VStack(spacing: 16) {
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
      .padding(16)
      .frame(maxHeight: .infinity, alignment: .top)
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .bleScanner:
          AnyView(BleScannerView(viewModel: .init()))
        case .bleServer:
          AnyView(BleServerView())
        default:
          fatalError("Not support")
        }
      }
      .navigationTitle("BleConn")
      .environmentObject(viewModel.router)
    }
  }
}

#Preview {
  SelectView(viewModel: .init(router: .init()))
}
