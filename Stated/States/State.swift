public typealias NoArguments = Void

///
///
///
public protocol State {
    associatedtype Arguments
    associatedtype MappedState

    static func create(arguments: Arguments, state: MappedState) -> Self
}

extension State {
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

    ///
    /// Create a slot that can only take this State in its position.
    ///
    public static var slot: StateSlot<Arguments, Self> {
        return StateSlot()
    }
}
