import Foundation

public struct InputSlot<Arguments>: Equatable, Hashable, CustomDebugStringConvertible {
    public let friendlyName: String
    let uuid: String

    public init(_ friendlyName: String? = nil) {
        let uuid = UUID().uuidString
        self.uuid = uuid
        self.friendlyName = friendlyName ?? uuid
    }

    public func withArgs(_ args: Arguments) -> StateMachineInput {
        return { sm in
            guard let potentialTransitions = sm.inputToTransitionTriggers[self.uuid] else { fatalError("Undefined transition") }

            for erasedTransitionTrigger in potentialTransitions {
                let result = erasedTransitionTrigger.tryTransition(args: args, stateMachine: sm)
                switch result {
                case .noMatch:
                    break
                case .triggered:
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

    public var debugDescription: String {
        return friendlyName
    }
}

public func input(_ friendlyName: String? = nil) -> InputSlot<Void> {
    return InputSlot(friendlyName)
}

public func input<Arguments>(_ friendlyName: String? = nil, taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot(friendlyName)
}

public func ==<Arguments, StateForSlot: State>(lhs: StateMachine.CurrentState, rhs: StateSlot<Arguments, StateForSlot>) -> Bool {
    return lhs.stateId == rhs.stateId
}
