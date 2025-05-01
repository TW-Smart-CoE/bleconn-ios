import Foundation

public class CallbackHolder<T> {
  private let timeout: TimeInterval
  private var callback: ((T) -> Void)?
  private var setTime: Date?

  public init(timeout: TimeInterval = 0) {
    self.timeout = timeout
  }

  public func isSet() -> Bool {
    guard let setTime = setTime else { return false }
    if timeout > 0 {
      return Date().timeIntervalSince(setTime) < timeout
    }
    return callback != nil
  }

  public func set(callback: @escaping (T) -> Void) {
    self.callback = callback
    self.setTime = Date()
  }

  public func resolve(result: T) {
    callback?(result)
    callback = nil
    setTime = nil
  }

  public func isTimeout() -> Bool {
    guard let setTime = setTime else { return false }
    return timeout > 0 && Date().timeIntervalSince(setTime) > timeout
  }
}

public class KeyCallbackHolder<K, T> {
  private let timeout: TimeInterval
  private var key: K?
  private var callback: ((T) -> Void)?
  private var setTime: Date?

  public init(timeout: TimeInterval = 0) {
    self.timeout = timeout
  }

  public func isSet() -> Bool {
    guard let setTime = setTime else { return false }
    if timeout > 0 {
      return Date().timeIntervalSince(setTime) < timeout
    }
    return key != nil && callback != nil
  }

  public func set(key: K, callback: @escaping (T) -> Void) {
    self.key = key
    self.callback = callback
    self.setTime = Date()
  }

  public func getKey() -> K? {
    return key
  }

  public func resolve(result: T) {
    callback?(result)
    callback = nil
    key = nil
    setTime = nil
  }

  public func isTimeout() -> Bool {
    guard let setTime = setTime else { return false }
    return timeout > 0 && Date().timeIntervalSince(setTime) > timeout
  }
}
