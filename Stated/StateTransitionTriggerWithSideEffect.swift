public struct SentInput<Arguments>: Equatable, CustomDebugStringConvertible {
    public let arguments: Arguments
    public let slot: InputSlot<Arguments>

    init(inputSlot: InputSlot<Arguments>, arguments: Arguments) {
        self.slot = inputSlot
        self.arguments = arguments
    }

    public static func ==(lhs: SentInput, rhs: SentInput) -> Bool {
        return lhs.slot.uuid == rhs.slot.uuid
    }

    public var debugDescription: String {
        return "Arguments: {\(arguments)} For: {\(slot)}"
    }
}

public func ==<Arguments>(lhs: SentInput<Arguments>, rhs: InputSlot<Arguments>) -> Bool {
    return lhs.slot.uuid == rhs.uuid
}

public class StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo: State>: StateTransitionTrigger<Arguments, StateFrom, StateTo> where StateTo.Arguments == Arguments {
    public let sideEffect: (StateMachine, SentInput<Arguments>, StateFrom, StateTo) -> Void

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>,
                sideEffect: @escaping (StateMachine, SentInput<Arguments>, StateFrom, StateTo) -> Void) {
        self.sideEffect = sideEffect
        super.init(inputSlot: inputSlot, transition: transition)
    }

    override func tryTransition(args: Any, stateMachine: StateMachine) -> TransitionResult {
        let result = super.tryTransition(args: args, stateMachine: stateMachine)
        switch result {
        case .noMatch:
            break
        case .triggered(let arguments, let fromState, let toState):
            let withArgs = SentInput<Arguments>(inputSlot: inputSlot, arguments: arguments as! Arguments)
            sideEffect(stateMachine, withArgs, fromState as! StateFrom, toState as! StateTo)
        }
        return result
    }
}
