import SwiftUI

@main
struct BleConnSampleApp: App {
  @StateObject private var dependency = DependencyImpl()

  var body: some Scene {
    WindowGroup {
      SelectView(viewModel: .init(dependency: dependency))
        .environmentObject(dependency)
    }
  }
}
