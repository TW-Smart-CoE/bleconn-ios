import Foundation
import Combine

class SelectViewModel: MVIViewModel {
  @Published var viewState: SelectState

  var router: Router

  init(
    initialState: SelectState = SelectState(),
    router: Router
  ) {
    self.viewState = initialState
    self.router = router
  }

  func reduce(currentState: SelectState, action: SelectAction) -> SelectState {
    var newState = currentState
    return newState
  }
  
  func runSideEffect(action: SelectAction, currentState: SelectState) {
    switch action {
    case .clickBleServer:
      router.navigate(to: AppRoute.bleServer)
      break
    case .clickBleScanner:
      router.navigate(to: AppRoute.bleScanner)
    }
  }
}
