import Foundation

public struct InputSlot<Arguments>: Equatable, Hashable {
    let uuid: String

    public init() {
        self.uuid = UUID().uuidString
    }

    public func withArgs(_ args: Arguments) -> StateMachineInput {
        return { sm in
            guard let potentialTransitions = sm.inputToTransitionTriggers[self.uuid] else { fatalError("Undefined transition") }

            for erasedTransitionTrigger in potentialTransitions {
                if erasedTransitionTrigger.tryTransition(args: args, stateMachine: sm) {
                    return
                }
            }

            fatalError("Undefined transition")
        }
    }

    public static func ==(lhs: InputSlot, rhs: InputSlot) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }
}

public func input() -> InputSlot<Void> {
    return InputSlot()
}

public func input<Arguments>(taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot()
}

public func ==<Arguments, StateForSlot: State>(lhs: StateMachine.CurrentState, rhs: StateSlot<Arguments, StateForSlot>) -> Bool {
    return lhs.stateId == rhs.stateId
}
