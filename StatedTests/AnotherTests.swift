import XCTest

//public class StateSlotWithLocalData<LocalState>: Equatable, Hashable {
//    let uuid: String
//
//    public init() {
//        self.uuid = UUID().uuidString
//    }
//
//    public static func ==(lhs: StateSlotWithLocalData, rhs: StateSlotWithLocalData) -> Bool {
//        return lhs.uuid == rhs.uuid
//    }
//
//    public var hashValue: Int {
//        return uuid.hashValue
//    }
//
//    public func to<ToInputArgs, LocalStateTo>(_ to: StateSlot<ToInputArgs, LocalState, LocalStateTo>) -> StateTransition<ToInputArgs, LocalState, LocalStateTo> {
//        return StateTransition(from: self, to: to)
//    }
//}
//
//public class StateSlot<Arguments, PreviousLocalState, LocalState>: StateSlotWithLocalData<LocalState> {
//    let mapInput: (Arguments, PreviousLocalState) -> LocalState
//
//    fileprivate init(mapInput: @escaping (Arguments, PreviousLocalState) -> LocalState) {
//        self.mapInput = mapInput
//        super.init()
//    }
//
//    public static func slot(mapInput: @escaping (Arguments, PreviousLocalState) -> LocalState) -> StateSlot<Arguments, PreviousLocalState, LocalState> {
//        return StateSlot.init(mapInput: mapInput)
//    }
//}
//
//public func state() -> StateSlot<Void, Void, Void> {
//    return StateSlot.slot()
//}
//
//public func state<Arguments, LocalState>(takingInput: @escaping (Arguments) -> LocalState) -> StateSlot<Arguments, Void, LocalState> {
//    return StateSlot.slot { (Arguments: Arguments, _: Void) -> LocalState in
//        return takingInput(Arguments)
//    }
//}
//
//public func state<PreviousLocalState, LocalState>(usingPreviousState: @escaping (PreviousLocalState) -> LocalState) -> StateSlot<Void, PreviousLocalState, LocalState> {
//    return StateSlot.slot { (_: Void, previous: PreviousLocalState) -> LocalState in
//        return usingPreviousState(previous)
//    }
//}
//
//public func state<Arguments, PreviousLocalState, LocalState>(taking: @escaping (Arguments, PreviousLocalState) -> LocalState) -> StateSlot<Arguments, PreviousLocalState, LocalState> {
//    return StateSlot.slot { (Arguments: Arguments, previous: PreviousLocalState) -> LocalState in
//        return taking(Arguments, previous)
//    }
//}
//
//public func state<PreviousLocalState>(discardingPreviousState: PreviousLocalState.Type) -> StateSlot<Void, PreviousLocalState, Void> {
//    return StateSlot.slot()
//}
//
//extension StateSlot where Arguments == Void {
//    public static func slot(mapInput: @escaping (PreviousLocalState) -> LocalState) -> StateSlot<Arguments, PreviousLocalState, LocalState> {
//        return StateSlot.init { (_: Arguments, previous: PreviousLocalState) -> LocalState in
//            return mapInput(previous)
//        }
//    }
//}
//
//extension StateSlot where PreviousLocalState == Void {
//    public static func slot(mapInput: @escaping (Arguments) -> LocalState) -> StateSlot<Arguments, PreviousLocalState, LocalState> {
//        return StateSlot.init { (args: Arguments, _: PreviousLocalState) -> LocalState in
//            return mapInput(args)
//        }
//    }
//}
//
//extension StateSlot where LocalState == Void {
//    public static func slot() -> StateSlot<Arguments, PreviousLocalState, LocalState> {
//        return StateSlot.init { (_: Arguments, _: PreviousLocalState) -> Void in
//            return
//        }
//    }
//}
