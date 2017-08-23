public class ErasedStateSlot<StateForSlot>: Equatable, Hashable {
    let stateId: String

    fileprivate init(stateId: String) {
        self.stateId = stateId
    }

    public static func ==(lhs: ErasedStateSlot, rhs: ErasedStateSlot) -> Bool {
        return lhs.stateId == rhs.stateId
    }

    public var hashValue: Int {
        return stateId.hashValue
    }

    public func _to<Arguments, StateTo: State>(_ to: StateSlot<Arguments, StateTo>, map: @escaping (StateForSlot) -> StateTo.MappedState) -> StateTransition<Arguments, StateForSlot, StateTo> {
        return StateTransition(from: self, to: to, map: map)
    }
}

public class StateSlot<Arguments, StateForSlot: State>: ErasedStateSlot<StateForSlot> {
    public init() {
        super.init(stateId: StateForSlot.stateId)
    }
}

public func ==<Arguments, StateForSlot: State>(lhs: StateSlot<Arguments, StateForSlot>, rhs: ErasedStateSlot<StateForSlot>) -> Bool {
    return lhs.stateId == rhs.stateId
}

public func ==<Arguments, StateForSlot: State>(lhs: StateSlot<Arguments, StateForSlot>, rhs: Any) -> Bool {
    if let state = rhs as? StateForSlot {
        return lhs.stateId == state.stateId
    } else if let stateSlot = rhs as? StateSlot<Arguments, StateForSlot> {
        return lhs.stateId == stateSlot.stateId
    }
    return false
}

public func ==<Arguments, StateForSlot: State>(lhs: Any, rhs: StateSlot<Arguments, StateForSlot>) -> Bool {
    return rhs == lhs
}
