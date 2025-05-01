import Foundation
import BleConn

class DependencyImpl: Dependency, ObservableObject {
  let logger: Logger
  var router: Router
  let bleClient: BleClient

  private let bluetoothQueue = DispatchQueue(label: "com.thoughtworks.bleconn")

  init() {
    self.logger = DefaultLogger()
    self.router = Router()
    self.bleClient = BleClient(logger: logger, queue: bluetoothQueue)
  }
}
