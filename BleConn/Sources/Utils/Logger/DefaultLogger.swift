import os.log

public class DefaultLogger: Logger {
  private let log = OSLog(subsystem: "com.thoughtworks.bleconn", category: "ble-ios")

  public init() {}

  public func debug(_ message: String) {
    os_log("[DEBUG] %{public}@", log: log, type: .debug, message)
  }

  public func info(_ message: String) {
    os_log("[INFO] %{public}@", log: log, type: .info, message)
  }

  public func error(_ message: String) {
    os_log("[ERROR] %{public}@", log: log, type: .error, message)
  }

  public func fault(_ message: String) {
    os_log("[FAULT] %{public}@", log: log, type: .fault, message)
  }
}
