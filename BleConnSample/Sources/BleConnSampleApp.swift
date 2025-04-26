//
//  BleConnSampleApp.swift
//  BleConnSample
//
//  Created by Jie Meng on 2025/4/22.
//

import SwiftUI

@main
struct BleConnSampleApp: App {
  @StateObject private var router = Router()

  var body: some Scene {
    WindowGroup {
      SelectView(viewModel: .init(router: router))
    }
  }
}
