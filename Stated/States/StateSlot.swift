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

    public func _to<Arguments, StateTo>(_ to: StateSlot<Arguments, StateTo>, map: @escaping (StateForSlot) -> StateTo.MappedState) -> StateTransition<Arguments, StateForSlot, StateTo> {
        return StateTransition(from: self, to: to, map: map)
    }
}

public class StateSlot<Arguments, StateForSlot: State>: ErasedStateSlot<StateForSlot> {
    public init() {
        super.init(stateId: StateForSlot.stateId)
    }
}
