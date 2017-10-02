public typealias NoArguments = Void

///
///
///
public protocol State: AnyState {
    associatedtype Arguments = NoArguments
    associatedtype MappedState = Void

    static func create(arguments: Arguments, state: MappedState) -> Self
}

extension State {
    /// Create a slot that can only take this State in its position.
    ///
    public static var slot: StateSlot<Arguments, Self> {
        return StateSlot()
    }
}
