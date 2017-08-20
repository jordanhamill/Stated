public class ErasedStateTransitionTrigger {
    let inputUuid: String
    private let trigger: (Any, StateMachine) -> Bool

    init(inputUuid: String, trigger: @escaping (Any, StateMachine) -> Bool) {
        self.inputUuid = inputUuid
        self.trigger = trigger
    }

    func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        return trigger(args, stateMachine)
    }
}

public class StateTransitionTrigger<Arguments, StateFrom, StateTo: State>: ErasedStateTransitionTrigger where StateTo.Arguments == Arguments {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<Arguments, StateFrom, StateTo>

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) {
        self.inputSlot = inputSlot
        self.transition = transition
        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
            guard stateMachine.currentState.stateId == transition.from.stateId else { return false }
            guard let typedArgs = args as? Arguments else { return false }

            transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
            return true
        })
    }
}

public func |<Arguments, StateFrom, StateTo: State>(input: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) -> StateTransitionTrigger<Arguments, StateFrom, StateTo> where StateTo.Arguments == Arguments {
    return StateTransitionTrigger(inputSlot: input, transition: transition)
}
