import XCTest
//import Stated

public class StateSlot: Equatable, Hashable {
    let uuid: String

    public init() {
        self.uuid = UUID().uuidString
    }

    public static func ==(lhs: StateSlot, rhs: StateSlot) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }
}

public class _IStateSlotWithLocalData<LocalState>: StateSlot {
    public override init() {
        super.init()
    }

    public func to<ToInputArgs, LocalStateTo>(_ to: IStateSlot<ToInputArgs, LocalState, LocalStateTo>) -> StateTransition<ToInputArgs, LocalState, LocalStateTo> {
        return StateTransition(from: self, to: to)
    }
}

public class _IStateSlotSlowWithLocalDataFromInput<InputArgs, LocalState>: _IStateSlotWithLocalData<LocalState> {
    public override init() {
        super.init()
    }
}

public class _IStateSlotSlowWithLocalDataFromInputAndPreviousState<InputArgs, PreviousLocalState, LocalState>: _IStateSlotSlowWithLocalDataFromInput<InputArgs, LocalState> {
    public override init() {
        super.init()
    }
}

public class IStateSlot<InputArgs, PreviousLocalState, LocalState>: _IStateSlotSlowWithLocalDataFromInputAndPreviousState<InputArgs, PreviousLocalState, LocalState> {
    let mapInput: (InputArgs, PreviousLocalState) -> LocalState

    public init(mapInput: @escaping (InputArgs, PreviousLocalState) -> LocalState) {
        self.mapInput = mapInput
        super.init()
    }
}



class StateadTests: XCTestCase {

    struct States {
        static let uninitialized = StateSlot()
        static let initializing = IStateSlot<Bool, Int, Bool> { input, previousState in
            return input
        }
    }

//    var stateMachine: StateMachine<State>!

    override func setUp() {

//        func initializeThing(input: InputSlot<Bool>, fromState: StateSlot<Void>, toState: StateSlot<Bool>, offline: Bool) {
//
//        }

    }
    
    func testExample() {
        
        XCTAssert(true)
    }
}



