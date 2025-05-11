import CoreBluetooth

struct ToastData: Equatable {
  let isShow: Bool
  let message: String
}

struct BleClientState: ViewState {
  var isConnected: Bool = false
  var mtu: String = "default"
  var services: [CBService] = []
  var requestMtu: Int = 256
  var toastData: ToastData = .init(isShow: false, message: "")
}

enum BleClientAction: Action {
  case navigateBack
  case readDeviceInfo
  case enableNotification
  case disableNotification
  case connectStatusChanged(isConnected: Bool)
  case onServicesDiscovered(services: [CBService])
  case discoverServices
  case requestMtu
  case writeWiFiConfig(ssid: String, password: String)
  case onMtuUpdated(mtu: Int)
  case onNotification(notification: String)
  case updateRequestMtu(number: Int)
  case disconnect
  case showToast(isShow: Bool, message: String)
}
