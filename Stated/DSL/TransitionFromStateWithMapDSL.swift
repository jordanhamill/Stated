public struct TransitionFromStateWithMap<InputArguments, ArgumentsForFromState, StateFrom: State, MappedState> {
    let transitionFromState: TransitionFromState<InputArguments, ArgumentsForFromState, StateFrom>
    let map: (StateFrom) -> MappedState

    public func to<StateTo>(_ to: StateSlot<InputArguments, StateTo>) -> StateTransitionTrigger<InputArguments, StateFrom, StateTo>
        where StateTo.Arguments == InputArguments, StateTo.MappedState == MappedState {
            let transition = transitionFromState.from._to(to, map: map)
            return StateTransitionTrigger(inputSlot: transitionFromState.input, transition: transition)
    }
}

///
/// Sugar for creating a mapped state transition e.g.
/// An alias for `TransitionFromStateWithMap.to(_: toState)` to be used when mapping is required in order to construct the `toState`.
/// ```
///   anInput.given(fromState).transition(with: { $0.prop }).to(toState)
/// ```
/// Using operators you can get readable arrow structure
/// ```
///   anInput | fromState => { $0.prop } => toState
/// ```
///
public func => <ArgumentsForToState, ArgumentsForFromState, StateFrom, StateTo>(
    transitionFromStateMap: TransitionFromStateWithMap<ArgumentsForToState, ArgumentsForFromState, StateFrom, StateTo.MappedState>,
    toState: StateSlot<ArgumentsForToState, StateTo>) -> StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>
    where StateTo.Arguments == ArgumentsForToState {
        return transitionFromStateMap.to(toState)
}
