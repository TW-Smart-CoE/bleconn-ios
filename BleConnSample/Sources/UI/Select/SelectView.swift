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
      .padding(.horizontal, 16)
      .navigationDestination(for: AppRoute.self) { route in
        viewModel.router.destinations(for: route)
      }
      .navigationTitle("BleConn")
      .environmentObject(viewModel.router)
    }
  }
}

#Preview {
  SelectView(viewModel: .init(router: .init()))
}
