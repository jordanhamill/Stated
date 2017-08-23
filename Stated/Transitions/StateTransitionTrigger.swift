public class AnyStateTransitionTrigger {
    enum TransitionResult {
        case noMatch
        case triggered(arguments: Any, fromState: Any, toState: Any)
    }

    let inputUuid: String
    private let trigger: (Any, StateMachine) -> TransitionResult

    init(inputUuid: String, trigger: @escaping (Any, StateMachine) -> TransitionResult) {
        self.inputUuid = inputUuid
        self.trigger = trigger
    }

    func tryTransition(args: Any, stateMachine: StateMachine) -> TransitionResult {
        return trigger(args, stateMachine)
    }
}

public class StateTransitionTrigger<Arguments, StateFrom, StateTo: State>: AnyStateTransitionTrigger where StateTo.Arguments == Arguments {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<Arguments, StateFrom, StateTo>

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) {
        self.inputSlot = inputSlot
        self.transition = transition
        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
            guard stateMachine.currentState.stateId == transition.from.stateId else { return .noMatch }
            let typedArgs = args as! Arguments

            let (fromState, toState) = transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
            return .triggered(arguments: args, fromState: fromState, toState: toState)
        })
    }
}
