extension InputSlot {
    ///
    /// Define the current state the system must be in for a valid transition.
    /// For example a transition to `stateB` will occur when the system receives `goToB` and the current state is
    /// `stateA`.
    /// ```
    ///   Inputs.goToB.given(States.stateA).transition(to: States.stateB)
    /// ```
    /// - parameter fromState: The current state constraint for the transition.
    ///
    public func given<ArgumentsForFromState, StateFrom>(_ fromState: StateSlot<ArgumentsForFromState, StateFrom>) -> TransitionFromState<Arguments, ArgumentsForFromState, StateFrom> {
        return TransitionFromState(input: self, from: fromState)
    }

    ///
    /// Alias for `given`.
    ///
    /// Define the current state the system must be in for a valid transition.
    /// For example a transition to `stateB` will occur when the system receives `goToB` and the current state is
    /// `stateA`.
    /// ```
    ///   Inputs.goToB.from(States.stateA).transition(to: States.stateB)
    /// ```
    /// - parameter fromState: The current state constraint for the transition.
    ///
    public func from<ArgumentsForStateSlot, StateForSlot>(_ fromState: StateSlot<ArgumentsForStateSlot, StateForSlot>) -> TransitionFromState<Arguments, ArgumentsForStateSlot, StateForSlot> {
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
///   let triggerableStateTransition = anInput | fromState => toState
/// ```
///
public func |<ArgumentsForToState, ArgumentsForFromState, StateFrom>(
    input: InputSlot<ArgumentsForToState>,
    fromState: StateSlot<ArgumentsForFromState, StateFrom>)
    -> TransitionFromState<ArgumentsForToState, ArgumentsForFromState, StateFrom> {
        return TransitionFromState(input: input, from: fromState)
}
