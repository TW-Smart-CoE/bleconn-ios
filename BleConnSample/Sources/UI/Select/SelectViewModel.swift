import Foundation
import Combine

class SelectViewModel: MVIViewModel {
  typealias S = SelectState
  typealias A = SelectAction

  @Published var viewState: SelectState

  private var router: Router

  init(
    initialState: SelectState = SelectState(),
    dependency: Dependency,
    router: Router
  ) {
    self.viewState = initialState
    self.router = router
  }

  func reduce(currentState: SelectState, action: SelectAction) -> SelectState {
    return currentState
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
