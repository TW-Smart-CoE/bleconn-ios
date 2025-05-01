import Foundation

public protocol Logger {
  func debug(_ message: String)
  func info(_ message: String)
  func error(_ message: String)
  func fault(_ message: String)
}

public extension Logger {
  func debug(tag: String, message: String) {
    debug("[\(tag)] \(message)")
  }

  func info(tag: String, message: String) {
    info("[\(tag)] \(message)")
  }

  func error(tag: String, message: String) {
    error("[\(tag)] \(message)")
  }

  func fault(tag: String, message: String) {
    fault("[\(tag)] \(message)")
  }
}
