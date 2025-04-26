import Foundation

struct SelectState: ViewState {
    var placeholder: String = ""
}

enum SelectAction: Action {
    case clickBleServer
    case clickBleScanner
}
