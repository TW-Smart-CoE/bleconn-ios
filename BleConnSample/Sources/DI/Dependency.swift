import Foundation
import BleConn

protocol Dependency {
  var logger: Logger { get }
  var router: Router { get }
  var bleClient: BleClient { get }
}
