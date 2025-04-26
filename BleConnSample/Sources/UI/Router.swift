import SwiftUI

enum AppRoute: Hashable {
  case bleScanner
  case bleServer
  case bleClient
}

class Router: ObservableObject {
  @Published var path = NavigationPath()

  func navigate(to route: AppRoute) {
    path.append(route)
  }

  func popToRoot() {
    path.removeLast(path.count)
  }

  func destinations(for route: AppRoute) -> some View {
    switch route {
    case .bleScanner:
      AnyView(BleScannerView())
    case .bleServer:
      AnyView(BleServerView())
    case .bleClient:
      fatalError("BLE Client View is not implemented yet.")
    }
  }
}
