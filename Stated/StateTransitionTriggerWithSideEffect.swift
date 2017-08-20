public class StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo: State>: StateTransitionTrigger<Arguments, StateFrom, StateTo> where StateTo.Arguments == Arguments {
    public var sideEffect: (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void = { _ in }

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>, sideEffect: @escaping (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void) {
        self.sideEffect = sideEffect
        super.init(inputSlot: inputSlot, transition: transition)
    }

    override func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        let transitioned = super.tryTransition(args: args, stateMachine: stateMachine)
        if transitioned {
            sideEffect(inputSlot, transition.from, transition.to, args as! Arguments)
        }
        return transitioned
    }
}

public func |<Arguments, StateFrom, StateTo: State>(
    transitionTrigger: StateTransitionTrigger<Arguments, StateFrom, StateTo>,
    effect: @escaping (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
    return StateTransitionTriggerWithSideEffect(inputSlot: transitionTrigger.inputSlot, transition: transitionTrigger.transition, sideEffect: effect)
}
