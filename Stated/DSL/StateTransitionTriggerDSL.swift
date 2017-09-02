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
public func |<ArgumentsForToState, StateFrom: AnyState, StateTo: State>(
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
public func |<ArgumentsForToState, StateFrom: AnyState, StateTo: State>(
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
public func |<ArgumentsForToState, StateFrom: AnyState, StateTo: State>(
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
public func |<ArgumentsForToState, StateFrom: AnyState, StateTo: State>(
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
public func |<ArgumentsForToState, StateFrom: AnyState, StateTo: State>(
    stateTransitionTrigger: StateTransitionTrigger<ArgumentsForToState, StateFrom, StateTo>,
    sideEffect: @escaping () -> Void)
    -> StateTransitionTriggerWithSideEffect<ArgumentsForToState, StateFrom, StateTo> {
        return stateTransitionTrigger.performingSideEffect(sideEffect)
}
