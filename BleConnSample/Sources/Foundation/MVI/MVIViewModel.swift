import Combine

public protocol MVIViewModel: ObservableObject {
  // swiftlint:disable:next type_name
  associatedtype S: ViewState
  associatedtype A: Action

  var viewState: S { get set }

  func reduce(currentState: S, action: A) -> S
  func runSideEffect(action: A, currentState: S)
}

extension MVIViewModel {
  public func dispatch(action: A) {
    let newState = self.reduce(currentState: self.viewState, action: action)
    self.viewState = newState
    self.runSideEffect(action: action, currentState: newState)
  }
}
