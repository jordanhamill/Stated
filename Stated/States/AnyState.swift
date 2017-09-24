public protocol AnyState { }

extension AnyState {
    ///
    /// Globally unique identifier for this state.
    ///
    static var stateId: String { return String(reflecting: Self.self) }

    ///
    /// Globally unique identifier for this state.
    ///
    var stateId: String { return Self.stateId }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.stateId == rhs.stateId
    }
}

public func ==<Arguments, StateForSlot>(lhs: StateSlot<Arguments, StateForSlot>, rhs: AnyState) -> Bool {
    return lhs.stateId == rhs.stateId
}

public func ==<Arguments, StateForSlot>(lhs: AnyState, rhs: StateSlot<Arguments, StateForSlot>) -> Bool {
    return rhs == lhs
}
