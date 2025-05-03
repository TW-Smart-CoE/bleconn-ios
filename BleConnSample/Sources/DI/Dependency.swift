import Foundation
import BleConn

protocol Dependency {
  var logger: Logger { get }
  var bleClient: BleClient { get }
}
