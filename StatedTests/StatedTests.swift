import XCTest
//import Stated

//infix operator =>: MultiplicationPrecedence
//public func => <Arguments, StateFrom, StateTo: State>(from: ErasedStateSlot<StateFrom>, to: StateSlot<Arguments, StateTo>) -> StateTransition<Arguments, StateFrom, StateTo>
//    where StateTo.Arguments == Arguments, StateTo.MappedState: AnyState {
//        return from.to(to)
//}

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

//public class StateTransitionTrigger<Arguments, StateFrom, StateTo: State>: ErasedStateTransitionTrigger where StateTo.Arguments == Arguments, StateTo.MappedState == StateFrom {
//    let inputSlot: InputSlot<Arguments>
//    let transition: StateTransition<Arguments, StateFrom, StateTo>
//
//    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) {
//        self.inputSlot = inputSlot
//        self.transition = transition
//        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
////            guard stateMachine.currentState.slotUuid == transition.from.uuid else { return false }
//            guard let typedArgs = args as? Arguments else { return false }
//
//            transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
//            return true
//        })
//    }
//}
//
//public class StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo>: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
//    public var sideEffect: (InputSlot<Arguments>, ErasedStateSlot<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void = { _ in }
//
//    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>, sideEffect: @escaping (InputSlot<Arguments>, ErasedStateSlot<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) {
//        self.sideEffect = sideEffect
//        super.init(inputSlot: inputSlot, transition: transition)
//    }
//
//    override func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
//        let transitioned = super.tryTransition(args: args, stateMachine: stateMachine)
//        if transitioned {
//            sideEffect(inputSlot, transition.from, transition.to, args as! Arguments)
//        }
//        return transitioned
//    }
//}


//public func |<Arguments, LocalStateFrom, LocalStateTo>(Arguments: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>) -> StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
//    return StateTransitionTrigger(inputSlot: Arguments, transition: transition)
//}


//public func |<Arguments, LocalStateFrom, LocalStateTo>(
//    transitionTrigger: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo>,
//    effect: @escaping (InputSlot<Arguments>, ErasedStateSlot<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo> {
//        return StateTransitionTriggerWithSideEffect(inputSlot: transitionTrigger.inputSlot, transition: transitionTrigger.transition, sideEffect: effect)
//}

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

public func input() -> InputSlot<Void> {
    return InputSlot()
}

public func input<Arguments>(taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot()
}

//public func ==<Arguments, PreviousLocalState, LocalState>(lhs: StateMachine.State<Any?>, rhs: StateSlot<Arguments, PreviousLocalState, LocalState>) -> Bool {
//    return lhs.slotUuid == rhs.uuid
//}

public typealias StateMachineInput = (StateMachine) -> Void
public class StateMachine {
    public struct CurrentState: Equatable {
        let slotUuid: String
        public let localState: Any

        public static func ==(lhs: CurrentState, rhs: CurrentState) -> Bool {
            return lhs.slotUuid == rhs.slotUuid
        }
    }

    fileprivate let mappings: [ErasedStateTransitionTrigger]
    fileprivate let inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]]
    fileprivate var currentState: CurrentState

    public init<InitialState: State>(initialState: InitialState, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = CurrentState(slotUuid: InitialState.uniqueId, localState: initialState)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    public func send(_ input: StateMachineInput) {
        input(self)
    }

    public func send(_ input: InputSlot<Void>) {
        input.withArgs(())(self)
    }

    func setNextState(state: CurrentState) {
        currentState = state
    }
}

public typealias NoArguments = Void

public protocol State: Equatable {
    associatedtype Arguments
    associatedtype MappedState

    static func create(arguments: Arguments, state: MappedState) -> Self
}

extension State {
    public static var uniqueId: String {
        return String(describing: self)
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return type(of: lhs).uniqueId == type(of: rhs).uniqueId
    }

    public static var slot: StateSlot<Arguments, Self> {
        return StateSlot()
    }
}

public class StateTransition<Arguments, StateFrom, StateTo: State> where StateTo.Arguments == Arguments {
    let from: ErasedStateSlot<StateFrom>
    let map: (StateFrom) -> StateTo.MappedState
    let to: StateSlot<Arguments, StateTo>

    init(from: ErasedStateSlot<StateFrom>, to: StateSlot<Arguments, StateTo>, map: @escaping (StateFrom) -> StateTo.MappedState) {
        self.from = from
        self.to = to
        self.map = map
    }

    func trigger(withInput arguments: Arguments, stateMachine: StateMachine) {
        let previousState = stateMachine.currentState.localState as! StateFrom
        let nextState = StateTo.create(arguments: arguments, state: map(previousState))
        let state = StateMachine.CurrentState(
            slotUuid: to.uuid,
            localState: nextState
        )
        stateMachine.setNextState(state: state)
    }
}


public protocol StateTakingInput: State {
    typealias MappedState = Void

    static func create(arguments: Arguments) -> Self
}

extension StateTakingInput {
    public static func create(arguments: Arguments, state: Void) -> Self {
        return self.create(arguments: arguments)
    }
}

public protocol StateUsingMappedState: State {
    typealias Arguments = NoArguments

    static func create(state: MappedState) -> Self
}

extension StateUsingMappedState {
    public static func create(arguments: NoArguments, state: MappedState) -> Self {
        return self.create(state: state)
    }
}

enum LaunchedFrom {
    case fresh
    case url(URL)
}

enum DeepLink {
    case viewPost(String)
    case friendRequest(String)
}

class StatedTests: XCTestCase {

    public struct UninitializedState: State {
        public typealias Arguments = Void
        public typealias MappedState = Void

        public static func create(arguments: Void, state: Void) -> UninitializedState {
            return UninitializedState()
        }

        init() { }//TODO
    }


    final class InitializedState: StateTakingInput {
        typealias MappedState = Void // boooo
        typealias Arguments = LaunchedFrom

        let deepLink: DeepLink?

        static func create(arguments: LaunchedFrom) -> StatedTests.InitializedState {
            let deepLink: DeepLink?
            switch arguments {
            case .fresh:
                deepLink = nil
            case .url:
                deepLink = DeepLink.viewPost("Blah")
            }
            return InitializedState(deepLink: deepLink)
        }

        private init(deepLink: DeepLink?) {
            self.deepLink = deepLink
        }
    }

    final class IndexingState: State  {
        typealias MappedState = DeepLink?
        typealias Arguments = Void

        let deepLink: DeepLink?

        static func create(arguments: Void, state: DeepLink?) -> StatedTests.IndexingState {
            return IndexingState(deepLink: state)
        }

        private init(deepLink: DeepLink?) {
            self.deepLink = deepLink
        }
    }

    struct LoggedInState: State {
        typealias MappedState = DeepLink?
        typealias Arguments = Void

        let deepLink: DeepLink?

        static func create(arguments: Void, state: DeepLink?) -> StatedTests.LoggedInState {
            return LoggedInState(deepLink: state)
        }

        private init(deepLink: DeepLink?) {
            self.deepLink = deepLink
        }
    }

    class AppLauncher {
        struct States {
            static let uninitialized = UninitializedState.slot
            static let initialized = InitializedState.slot
            static let indexing = IndexingState.slot
            static let loggedIn = LoggedInState.slot
        }

        struct Inputs {
            static let initialize = input(taking: LaunchedFrom.self)
            static let upgrade = input()
            static let indexDatabase = input()
            static let logIn = input() // Take in Account
            static let logOut = input()
        }

        // MARK: Private propteries

        private var machine: StateMachine!

        // MARK: Lifecycle

        init() {
            machine = StateMachine(initialState: UninitializedState(), mappings: [])

            States.uninitialized._to(States.initialized) { _ in }
            States.initialized._to(States.indexing) { $0.deepLink }
            States.indexing._to(States.loggedIn) { $0.deepLink }
            States.initialized._to(States.loggedIn) { $0.deepLink }

            machine.send(Inputs.initialize.withArgs(.fresh))
        }
        
        // MARK: Internal methods
        
        func initialize() {
            machine.send(Inputs.initialize.withArgs(.fresh))
        }
    }

    var appLauncher: AppLauncher!
    override func setUp() {
        appLauncher = AppLauncher()
    }

    func testExample() {
        appLauncher.initialize()
//        XCTAssert(stateMachine.currentState == States.initializing)
//
//        stateMachine.send(Inputs.indexDatabase)
//        XCTAssert(stateMachine.currentState == States.indexing)

        // todo build composite state machine - can it be formalized as nicely as article
    }
}



