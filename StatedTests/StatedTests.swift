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

public class StateTransitionTrigger<Arguments, StateFrom, StateTo: State>: ErasedStateTransitionTrigger where StateTo.Arguments == Arguments {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<Arguments, StateFrom, StateTo>

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) {
        self.inputSlot = inputSlot
        self.transition = transition
        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
            guard stateMachine.currentState.stateId == transition.from.stateId else { return false }
            guard let typedArgs = args as? Arguments else { return false }

            transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
            return true
        })
    }
}

public class StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo: State>: StateTransitionTrigger<Arguments, StateFrom, StateTo> where StateTo.Arguments == Arguments {
    public var sideEffect: (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void = { _ in }

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>, sideEffect: @escaping (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void) {
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


public func |<Arguments, StateFrom, StateTo: State>(input: InputSlot<Arguments>, transition: StateTransition<Arguments, StateFrom, StateTo>) -> StateTransitionTrigger<Arguments, StateFrom, StateTo> where StateTo.Arguments == Arguments {
    return StateTransitionTrigger(inputSlot: input, transition: transition)
}


public func |<Arguments, StateFrom, StateTo: State>(
    transitionTrigger: StateTransitionTrigger<Arguments, StateFrom, StateTo>,
    effect: @escaping (InputSlot<Arguments>, ErasedStateSlot<StateFrom>, StateSlot<Arguments, StateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, StateFrom, StateTo> {
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

public func input() -> InputSlot<Void> {
    return InputSlot()
}

public func input<Arguments>(taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot()
}

public func ==<Arguments, StateForSlot: State>(lhs: StateMachine.CurrentState, rhs: StateSlot<Arguments, StateForSlot>) -> Bool {
    return lhs.stateId == rhs.stateId
}

public typealias StateMachineInput = (StateMachine) -> Void
public class StateMachine {
    public struct CurrentState: Equatable {
        let stateId: String
        public let localState: Any

        public static func ==(lhs: CurrentState, rhs: CurrentState) -> Bool {
            return lhs.stateId == rhs.stateId
        }
    }

    fileprivate let mappings: [ErasedStateTransitionTrigger]
    fileprivate let inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]]
    fileprivate var currentState: CurrentState

    public init<InitialState: State>(initialState: InitialState, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = CurrentState(stateId: initialState.stateId, localState: initialState)
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

public protocol State {//: Equatable {
    associatedtype Arguments
    associatedtype MappedState

    static func create(arguments: Arguments, state: MappedState) -> Self
}

extension State {
    static var stateId: String { return String(describing: Self.self) }
    var stateId: String { return Self.stateId }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.stateId == type(of: rhs).stateId
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
            stateId: to.stateId,
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

        init() { }
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

        var machine: StateMachine!

        // MARK: Lifecycle

        init() {
            let mappings: [ErasedStateTransitionTrigger] = [
                Inputs.initialize    | States.uninitialized._to(States.initialized) { _ in },
                Inputs.indexDatabase | States.initialized._to(States.indexing) { $0.deepLink },
                Inputs.logIn         | States.indexing._to(States.loggedIn) { $0.deepLink },
                Inputs.logIn         | States.initialized._to(States.loggedIn) { $0.deepLink },
                Inputs.logOut        | States.initialized._to(States.loggedIn) { $0.deepLink }
            ]
            machine = StateMachine(initialState: UninitializedState(), mappings: mappings)
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
        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.uninitialized)
        appLauncher.machine.send(AppLauncher.Inputs.initialize.withArgs(.fresh))
        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.initialized)

//        appLauncher.machine.send(AppLauncher.Inputs.indexDatabase)
//        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.indexing)

        appLauncher.machine.send(AppLauncher.Inputs.logIn)
        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.loggedIn)

        // todo build composite state machine - can it be formalized as nicely as article
    }
}



