import XCTest

//public typealias AnyPreviousState = Void

public protocol AnyState {
//    private init() { }
}

public struct AnyPreviousState: AnyState {

}

public class StateSlotWithLocalData<LocalState: AnyState>: Equatable, Hashable {
    let uuid: String

    public init() {
        self.uuid = UUID().uuidString//LocalState.uniqueId
    }

    public static func ==(lhs: StateSlotWithLocalData, rhs: StateSlotWithLocalData) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }

    // StateTo
//    public func _to<Arguments, StateTo: State>(_ to: StateSlotWithLocalData<StateTo>) //-> StateTransition<Arguments, LocalState, StateTo>
//        where StateTo.Arguments == Arguments, StateTo.PreviousState == LocalState {
//        return StateTransition(from: self, to: to)
//    }

    public func to<Arguments, StateTo: State>(_ to: StateSlot<Arguments, StateTo>) -> StateTransition<Arguments, LocalState, StateTo>
        where StateTo.PreviousState == LocalState, StateTo.Arguments == Arguments, StateTo.PreviousState: AnyState {
        return StateTransition(from: self, to: to)
    }
}

// todo relax StateFrom: State to just blank StateFrom

public class StateSlot<Arguments, LocalState: AnyState>: StateSlotWithLocalData<LocalState> {
    public override init() {
        super.init()
    }
}
