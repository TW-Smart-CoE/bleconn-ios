import SwiftUI

@main
struct BleConnSampleApp: App {
  @StateObject private var dependency = DependencyImpl()
  @StateObject private var router = Router()

  var body: some Scene {
    WindowGroup {
      SelectView(dependency: dependency, router: router)
    }
    .environmentObject(dependency)
    .environmentObject(router)
  }
}
