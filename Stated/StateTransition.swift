public struct StateTransition<State> {
    let currentStateMatches: (State) -> Bool
    let nextState: State

    fileprivate init(currentStateCondition: @escaping (State) -> Bool, nextState: State) {
        self.currentStateMatches = currentStateCondition
        self.nextState = nextState
    }
}

infix operator =>: MultiplicationPrecedence

public func => <State: Equatable>(state: State, nextState: State) -> StateTransition<State> {
    return { $0 == state } => nextState
}

public func => <State>(condition: @escaping (State) -> Bool, nextState: State) -> StateTransition<State> {
    return StateTransition(currentStateCondition: condition, nextState: nextState)
}
