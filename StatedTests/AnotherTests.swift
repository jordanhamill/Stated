import XCTest

//public typealias AnyMappedState = Void


public class ErasedStateSlot<StateForSlot>: Equatable, Hashable {
    let uuid: String

    init() { // TODO access
        self.uuid = UUID().uuidString // TODO
    }

    public static func ==(lhs: ErasedStateSlot, rhs: ErasedStateSlot) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }

    public func _to<Arguments, StateTo: State>(_ to: StateSlot<Arguments, StateTo>, map: @escaping (StateForSlot) -> StateTo.MappedState) -> StateTransition<Arguments, StateForSlot, StateTo> {
            return StateTransition(from: self, to: to, map: map)
    }
}

public class StateSlot<Arguments, StateForSlot: State>: ErasedStateSlot<StateForSlot> {
    public override init() {
        super.init()
    }
}
