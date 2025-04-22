//
//  ContentView.swift
//  BleConnSample
//
//  Created by Jie Meng on 2025/4/22.
//

import SwiftUI
import BleConn

class ContentViewState: ObservableObject {
  @Published var bleScanner = BleScanner()
  @Published var isScanning = false
}

struct ContentView: View {
  @StateObject private var state = ContentViewState()

  var body: some View {
    VStack {
      Button(state.isScanning ? "Stop Scanning" : "Start Scanning") {
        if state.isScanning {
          state.bleScanner.stop()
          state.isScanning = false
        } else {
          let started = state.bleScanner.start(
            onFound: { peripheral, advertisementData, rssi in
              print("Found device: \(peripheral.name ?? "Unknown") - RSSI: \(rssi)")
            },
            onError: { error in
              print("Error: \(error?.localizedDescription ?? "Unknown error")")
            }
          )
          state.isScanning = started
        }
      }
      .padding()
    }
  }
}

#Preview {
  ContentView()
}
