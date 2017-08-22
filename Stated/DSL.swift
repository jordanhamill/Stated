infix operator =>: AdditionPrecedence

extension InputSlot {
    public func given<ArgumentsForFromState, StateFrom: State>(_ fromState: StateSlot<ArgumentsForFromState, StateFrom>) -> TransitionFromState<Arguments, ArgumentsForFromState, StateFrom> {
        return TransitionFromState(input: self, from: fromState)
    }

    /// 
    /// Alias for `given`.
    ///
    public func from<ArgumentsForStateSlot, StateForSlot: State>(_ fromState: StateSlot<ArgumentsForStateSlot, StateForSlot>) -> TransitionFromState<Arguments, ArgumentsForStateSlot, StateForSlot> {
        return given(fromState)
    }
}

///
/// Sugar for constructing a transition trigger given an input.
/// This is an alias for `InputSlot.given` and `InputSlot.from`.
/// ```
///   anInput.given(fromState).transition(to: toState)
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let transition = fromState => toState
///   let triggerableStateTransition = anInput | fromState => toState
/// ```
///
public func |<ArgumentsForToState, ArgumentsForFromState, StateFrom: State>(
    input: InputSlot<ArgumentsForToState>,
    fromState: StateSlot<ArgumentsForFromState, StateFrom>)
    -> TransitionFromState<ArgumentsForToState, ArgumentsForFromState, StateFrom> {
        return TransitionFromState(input: input, from: fromState)
}


public struct TransitionFromState<InputArguments, ArgumentsForFromState, StateFrom: State> {
    let input: InputSlot<InputArguments>
    let from: StateSlot<ArgumentsForFromState, StateFrom>

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

public struct TransitionFromStateWithMap<InputArguments, ArgumentsForFromState, StateFrom: State, MappedState> {
    let transitionFromState: TransitionFromState<InputArguments, ArgumentsForFromState, StateFrom>
    let map: (StateFrom) -> MappedState

    public func to<StateTo: State>(_ to: StateSlot<InputArguments, StateTo>) -> StateTransitionTrigger<InputArguments, StateFrom, StateTo>
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
public func => <ArgumentsForToState, ArgumentsForFromState, StateFrom: State, StateTo: State>(
    transitionFromStateMap: TransitionFromStateWithMap<ArgumentsForToState, ArgumentsForFromState, StateFrom, StateTo.MappedState>,
    toState: StateSlot<ArgumentsForToState, StateTo>) -> StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>
    where StateTo.Arguments == ArgumentsForToState {
    return transitionFromStateMap.to(toState)
}

extension StateTransitionTrigger {
    public func performingSideEffect(_ sideEffect: @escaping (StateMachine, StateTo, StateFrom, SentInput<Arguments>) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
        return StateTransitionTriggerWithSideEffect(
            inputSlot: self.inputSlot,
            transition: self.transition,
            sideEffect: sideEffect
        )
    }

    public func performingSideEffect(_ sideEffect: @escaping (StateMachine, StateTo, StateFrom) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
        return self.performingSideEffect { stateMachine, to, from, input in
            sideEffect(stateMachine, to, from)
        }
    }

    public func performingSideEffect(_ sideEffect: @escaping (StateMachine, StateTo) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
        return self.performingSideEffect { stateMachine, to, _, _ in
            sideEffect(stateMachine, to)
        }
    }

    public func performingSideEffect(_ sideEffect: @escaping (StateMachine) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
        return self.performingSideEffect { stateMachine, _, _, _ in
            sideEffect(stateMachine)
        }
    }

    public func performingSideEffect(_ sideEffect: @escaping () -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
        return self.performingSideEffect { _, _, _, _ in
            sideEffect()
        }
    }
}

///
/// Sugar for performing a side effect when a state transition occurs.
/// This is an alias for `StateTransitionTrigger.performingSideEffect`.
/// ```
///   anInput.given(fromState).transition(to: toState).performingSideEffect { stateMachine, toState, fromState, input in print("Side Effect") }
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let triggerableStateTransition = anInput | fromState => toState | { stateMachine, toState, fromState, input in print("Side Effect") }
/// ```
///
public func |<ArgumentsForToState, StateFrom, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping (StateMachine, StateTo, StateFrom, SentInput<ArgumentsForToState>) -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}

///
/// Sugar for performing a side effect when a state transition occurs.
/// This is an alias for `StateTransitionTrigger.performingSideEffect`.
/// ```
///   anInput.given(fromState).transition(to: toState).performingSideEffect { stateMachine, toState, fromState in print("Side Effect") }
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let triggerableStateTransition = anInput | fromState => toState | { stateMachine, toState, fromState in print("Side Effect") }
/// ```
///
public func |<ArgumentsForToState, StateFrom, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping (StateMachine, StateTo, StateFrom) -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}

///
/// Sugar for performing a side effect when a state transition occurs.
/// This is an alias for `StateTransitionTrigger.performingSideEffect`.
/// ```
///   anInput.given(fromState).transition(to: toState).performingSideEffect { stateMachine, toState in print("Side Effect") }
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let triggerableStateTransition = anInput | fromState => toState | { stateMachine, toState in print("Side Effect") }
/// ```
///
public func |<ArgumentsForToState, StateFrom, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping (StateMachine, StateTo) -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}

///
/// Sugar for performing a side effect when a state transition occurs.
/// This is an alias for `StateTransitionTrigger.performingSideEffect`.
/// ```
///   anInput.given(fromState).transition(to: toState).performingSideEffect { stateMachine in print("Side Effect") }
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let triggerableStateTransition = anInput | fromState => toState | { stateMachine in print("Side Effect") }
/// ```
///
public func |<ArgumentsForToState, StateFrom, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping (StateMachine) -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}

///
/// Sugar for performing a side effect when a state transition occurs.
/// This is an alias for `StateTransitionTrigger.performingSideEffect`.
/// ```
///   anInput.given(fromState).transition(to: toState).performingSideEffect { print("Side Effect") }
/// ```
/// Using operators you can get a table-like structure for easier reference:
/// ```
///   let triggerableStateTransition = anInput | fromState => toState | { print("Side Effect") }
/// ```
///
public func |<ArgumentsForToState, StateFrom, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping () -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}
