import CoreBluetooth

public class Result {
  public let isSuccess: Bool
  public let errorMessage: String

  public init(isSuccess: Bool = false, errorMessage: String = "") {
    self.isSuccess = isSuccess
    self.errorMessage = errorMessage
  }
}

public class DiscoverServicesResult: Result {
  public let services: [CBService]

  public init(isSuccess: Bool = false, errorMessage: String = "", services: [CBService] = []) {
    self.services = services
    super.init(isSuccess: isSuccess, errorMessage: errorMessage)
  }
}

public class MtuResult: Result {
  public let mtu: Int

  public init(isSuccess: Bool = false, errorMessage: String = "", mtu: Int = 0) {
    self.mtu = mtu
    super.init(isSuccess: isSuccess, errorMessage: errorMessage)
  }
}

public class ReadResult: Result {
  public let value: Data

  public init(isSuccess: Bool = false, errorMessage: String = "", value: Data = Data()) {
    self.value = value
    super.init(isSuccess: isSuccess, errorMessage: errorMessage)
  }
}

public struct NotificationData: Equatable {
  public let value: Data

  public init(value: Data) {
    self.value = value
  }

  public static func == (lhs: NotificationData, rhs: NotificationData) -> Bool {
    return lhs.value == rhs.value
  }
}
