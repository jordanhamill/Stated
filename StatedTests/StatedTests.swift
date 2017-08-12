import XCTest
//import Stated

public class StateTransition<Arguments, LocalStateFrom, LocalStateTo> {
    let from: StateSlotWithLocalData<LocalStateFrom>
    let to: StateSlot<Arguments, LocalStateFrom, LocalStateTo>

    init(from: StateSlotWithLocalData<LocalStateFrom>, to: StateSlot<Arguments, LocalStateFrom, LocalStateTo>) {
        self.from = from
        self.to = to
    }

    func trigger(withInput Arguments: Arguments, stateMachine: StateMachine) {
        let nextStateLocalState = to.mapInput(Arguments, stateMachine.currentState.localState as! LocalStateFrom)
        let nextState = StateMachine.State<Any?>(
            slotUuid: to.uuid,
            localState: nextStateLocalState
        )
        stateMachine.setNextState(state: nextState)
    }
}

infix operator =>: MultiplicationPrecedence
public func =><Arguments, LocalStateFrom, LocalStateTo>(from: StateSlotWithLocalData<LocalStateFrom>, to: StateSlot<Arguments, LocalStateFrom, LocalStateTo>) -> StateTransition<Arguments, LocalStateFrom, LocalStateTo> {
    return from.to(to)
}



public class ErasedStateTransitionTrigger {
    let inputUuid: String
    private let trigger: (Any, StateMachine) -> Bool

    init(inputUuid: String, trigger: @escaping (Any, StateMachine) -> Bool) {
        self.inputUuid = inputUuid
        self.trigger = trigger
    }

    func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        return trigger(args, stateMachine)
    }
}

public class StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo>: ErasedStateTransitionTrigger {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>) {
        self.inputSlot = inputSlot
        self.transition = transition
        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
            guard stateMachine.currentState.slotUuid == transition.from.uuid else { return false }
            guard let typedArgs = args as? Arguments else { return false }

            transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
            return true
        })
    }
}

public class StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo>: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
    public var sideEffect: (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void = { _ in }

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>, sideEffect: @escaping (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) {
        self.sideEffect = sideEffect
        super.init(inputSlot: inputSlot, transition: transition)
    }

    override func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        let transitioned = super.tryTransition(args: args, stateMachine: stateMachine)
        if transitioned {
            sideEffect(inputSlot, transition.from, transition.to, args as! Arguments)
        }
        return transitioned
    }
}


public func |<Arguments, LocalStateFrom, LocalStateTo>(Arguments: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>) -> StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
    return StateTransitionTrigger(inputSlot: Arguments, transition: transition)
}


public func |<Arguments, LocalStateFrom, LocalStateTo>(
    transitionTrigger: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo>,
    effect: @escaping (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo> {
        return StateTransitionTriggerWithSideEffect(inputSlot: transitionTrigger.inputSlot, transition: transitionTrigger.transition, sideEffect: effect)
}

public struct InputSlot<Arguments>: Equatable, Hashable {
    fileprivate let uuid: String

    public init() {
        self.uuid = UUID().uuidString
    }

    public func withArgs(_ args: Arguments) -> StateMachineInput {
        return { sm in
            guard let potentialTransitions = sm.inputToTransitionTriggers[self.uuid] else { fatalError("Undefined transition") }

            for erasedTransitionTrigger in potentialTransitions {
                if erasedTransitionTrigger.tryTransition(args: args, stateMachine: sm) {
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
}

public func input<Arguments>() -> InputSlot<Arguments> {
    return InputSlot()
}

public func Arguments<Arguments>(taking: Arguments.Type) -> InputSlot<Arguments> {
    return input()
}

public func ==<Arguments, PreviousLocalState, LocalState>(lhs: StateMachine.State<Any?>, rhs: StateSlot<Arguments, PreviousLocalState, LocalState>) -> Bool {
    return lhs.slotUuid == rhs.uuid
}

public typealias StateMachineInput = (StateMachine) -> Void
public class StateMachine {
    public struct State<LocalState>: Equatable {
        let slotUuid: String
        public let localState: LocalState

        public static func ==(lhs: State, rhs: State) -> Bool {
            return lhs.slotUuid == rhs.slotUuid
        }
    }

    fileprivate let mappings: [ErasedStateTransitionTrigger]
    fileprivate let inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]]
    fileprivate var currentState: State<Any?>

    init<Arguments, PreviousLocalState, LocalState>(initialState: StateSlot<Arguments, PreviousLocalState, LocalState>, localState: LocalState, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = State(slotUuid: initialState.uuid, localState: localState)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    func send(_ Arguments: StateMachineInput) {
        Arguments(self)
    }

    func send(_ Arguments: InputSlot<Void>) {
        Arguments.withArgs(())(self)
    }

    func setNextState(state: State<Any?>) {
        currentState = state
    }
}

class StatedTests: XCTestCase {
//    enum B: StateSlot {
//        case t = StateSlot()
//    }

    struct States {
        static let uninitialized = state() //StateSlot<Void, Void, Void>.slot()

        static let initializing = state(takingInput: { (Arguments: Bool) in
            return Arguments
        })

        static let indexing = state(discardingPreviousState: Bool.self)// StateSlot<Void, Bool, Void>.slot() This only allows similarly shaped previous states...

        static let loggedIn = state(usingPreviousState: { (previous: Bool) in
            return ("test", previous)
        })

        static let done = state(taking: { (Arguments: String, previous: Bool) in
            return "\(Arguments) \(previous)"
        })
    }

    struct Inputs {
        static let initialize = Arguments(taking: Bool.self)
        static let indexDatabase = InputSlot<Void>()
        static let logIn = InputSlot<String>()
    }

    var stateMachine: StateMachine!

    override func setUp() {

        // TODO Make state sig nicer
        func initializeThing(Arguments: InputSlot<Bool>, fromState: StateSlotWithLocalData<Void>, toState: StateSlot<Bool, Void, Bool>, offline: Bool) {
            print("Side effects bitches")
        }

        func indexStuff(Arguments: InputSlot<Void>, fromState: StateSlotWithLocalData<Bool>, toState: StateSlot<Void, Bool, Void>, _: Void) {
            print("Indexing")
        }

        let mappings: [ErasedStateTransitionTrigger] =  [
            // Input             |          from         =>    to               | side effect
            Inputs.initialize    |  States.uninitialized => States.initializing | initializeThing,
            Inputs.indexDatabase |  States.initializing  => States.indexing     | indexStuff
        ]

        let initial = States.uninitialized
        stateMachine = StateMachine(initialState: initial, localState: (), mappings: mappings)
    }

    func testExample() {
        stateMachine.send(Inputs.initialize.withArgs(true))
        XCTAssert(stateMachine.currentState == States.initializing)

        stateMachine.send(Inputs.indexDatabase)
        XCTAssert(stateMachine.currentState == States.indexing)

        // todo build composite state machine - can it be formalized as nicely as article
    }
}



