infix operator =>: AdditionPrecedence

///
/// Intermediary DSL object for constructing a transition given an input, current state and destination state.
///
public struct TransitionFromState<InputArguments, ArgumentsForFromState, StateFrom: State> {

    // MARK: Public

    let input: InputSlot<InputArguments>
    let from: StateSlot<ArgumentsForFromState, StateFrom>

    // MARK: Public

    public func transition<MappedState>(with map: @escaping (StateFrom) -> MappedState) -> TransitionFromStateWithMap<InputArguments, ArgumentsForFromState, StateFrom, MappedState> {
        return TransitionFromStateWithMap(transitionFromState: self, map: map)
    }

    ///
    /// Alias for `transition(with:)`
    ///
    public func passes<MappedState>(_ map: @escaping (StateFrom) -> MappedState) -> TransitionFromStateWithMap<InputArguments, ArgumentsForFromState, StateFrom, MappedState> {
        return transition(with: map)
    }

    public func transition<StateTo: State>(to: StateSlot<InputArguments, StateTo>) -> StateTransitionTrigger<InputArguments, StateFrom, StateTo>
        where StateTo.Arguments == InputArguments, StateTo.MappedState == Void {

            let map: (StateFrom) -> StateTo.MappedState = {_ in
                return ()
            }

            let transition = from._to(to, map: map)
            return StateTransitionTrigger(inputSlot: input, transition: transition)
    }
}


///
/// Sugar for creating a state transition e.g.
/// An alias for `TransitionFromState.transition(to:)` to be used when mapping is not required.
/// ```
///   anInput.given(fromState).transition(to: toState)
/// ```
/// Using operators you can get readable arrow structure
/// ```
///   anInput | fromState => toState
/// ```
///
public func => <ArgumentsForToState, ArgumentsForFromState, StateFrom: State, StateTo: State>(
    transitionFromState: TransitionFromState<ArgumentsForToState, ArgumentsForFromState, StateFrom>,
    toState: StateSlot<ArgumentsForToState, StateTo>) -> StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>
    where StateTo.Arguments == ArgumentsForToState, StateTo.MappedState == Void {
        return transitionFromState.transition(to: toState)
}

///
/// Sugar for creating a mapped state transition e.g.
/// An alias for `TransitionFromState.transition(with: { $0.prop })` to be used when mapping is required in order to construct the `toState`.
/// ```
///   anInput.given(fromState).transition(with: { $0.prop })
/// ```
/// Using operators you can get readable arrow structure
/// ```
///   anInput | fromState => { $0.prop }
/// ```
///
public func => <ArgumentsForToState, ArgumentsForFromState, StateFrom: State, MappedState>(
    transitionFromState: TransitionFromState<ArgumentsForToState, ArgumentsForFromState, StateFrom>,
    map: @escaping (StateFrom) -> MappedState) -> TransitionFromStateWithMap<ArgumentsForToState, ArgumentsForFromState, StateFrom, MappedState> {
    return transitionFromState.transition(with: map)
}
