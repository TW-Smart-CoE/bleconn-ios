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
}
