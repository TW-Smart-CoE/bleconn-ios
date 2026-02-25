import Foundation
import BleConn

class DependencyImpl: Dependency, ObservableObject {
  let logger: Logger
  let bleClient: BleClient

  private let bluetoothQueue = DispatchQueue(label: "com.jmengxy.bleconn")

  init() {
    self.logger = DefaultLogger()
    self.bleClient = BleClient(logger: logger, queue: bluetoothQueue)
  }
}
