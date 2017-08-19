import XCTest
//import Stated

//infix operator =>: MultiplicationPrecedence
//public func =><Arguments, StateFrom: State, StateTo: State>(from: StateFrom.Type, to: StateTo.Type) -> StateTransition<Arguments, StateFrom, StateTo> {
//    return from.to(to)
//}
//

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

//public class StateTransitionTrigger<Arguments, StateFrom, StateTo: State>: ErasedStateTransitionTrigger where StateTo.Arguments == Arguments, StateTo.PreviousState == StateFrom {
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
//    public var sideEffect: (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void = { _ in }
//
//    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>, sideEffect: @escaping (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) {
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
//    effect: @escaping (InputSlot<Arguments>, StateSlotWithLocalData<LocalStateFrom>, StateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo> {
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

    public func send(_ Arguments: StateMachineInput) {
        Arguments(self)
    }

    public func send(_ Arguments: InputSlot<Void>) {
        Arguments.withArgs(())(self)
    }

    func setNextState(state: CurrentState) {
        currentState = state
    }
}

public typealias NoArguments = Void

public protocol State: Equatable, AnyState {
    associatedtype Arguments
    associatedtype PreviousState

    static func create(arguments: Arguments, previousState: PreviousState) -> Self
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

public class StateTransition<Arguments, StateFrom: AnyState, StateTo: State> where StateTo.Arguments == Arguments {//, StateTo.PreviousState == StateFrom {
    let from: StateSlotWithLocalData<StateFrom>
    let to: StateSlot<Arguments, StateTo>

    init(from: StateSlotWithLocalData<StateFrom>, to: StateSlot<Arguments, StateTo>) {
        self.from = from
        self.to = to
    }

    func trigger(withInput arguments: Arguments, stateMachine: StateMachine) {
        let previousState = stateMachine.currentState.localState as! StateTo.PreviousState
        let nextState = StateTo.create(arguments: arguments, previousState: previousState)
        let state = StateMachine.CurrentState(
            slotUuid: to.uuid,
            localState: nextState
        )
        stateMachine.setNextState(state: state)
    }
}


//public protocol StateTakingInput: State {
//    typealias PreviousState = AnyState
//
//    static func create(arguments: Arguments) -> Self
//}
//
//extension StateTakingInput {
//    public static func create(arguments: Arguments, previousState: AnyState) -> Self {
//        return self.create(arguments: arguments)
//    }
//}
//
//public protocol StateUsingPreviousState: State {
//    typealias Arguments = NoArguments
//
//    static func create(previousState: PreviousState) -> Self
//}
//
//extension StateUsingPreviousState {
//    public static func create(arguments: NoArguments, previousState: PreviousState) -> Self {
//        return self.create(previousState: previousState)
//    }
//}

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
        public typealias PreviousState = AnyPreviousState

        public static func create(arguments: Void, previousState: AnyPreviousState) -> UninitializedState {
            return UninitializedState()
        }

        private init() { }
    }

    struct InitializedState: State {
        typealias PreviousState = UninitializedState // boooo
        typealias Arguments = LaunchedFrom

        let deepLink: DeepLink?

        static func create(arguments: LaunchedFrom, previousState: UninitializedState) -> StatedTests.InitializedState {
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

    class AppLauncher {
        struct States {
            static let uninitialized = UninitializedState.slot
            static let initialized = InitializedState.slot

//            static let uninitialized = state(takingInput: { (launchedFrom: LaunchedFrom) -> DeepLink? in
//                switch launchedFrom {
//                case .fresh:
//                    return nil
//                case .url:
//                    return DeepLink.viewPost("Blah")
//                }
//            })
//
//            static let initialized = state(usingPreviousState: { (deepLink: DeepLink?) -> DeepLink? in
//                return deepLink
//            })// This now forward on as a composed up state of `FromUrl`/Deep navigation link destination for app
        }

        struct Inputs {
//            static let initialize = input(taking: LaunchedFrom.self) // Input FromUrl
            static let initialize = input()
            static let upgrade = input()
            static let indexDatabase = input()
            static let logIn = input() // Take in Account
            static let logOut = input()
        }

        // MARK: Private propteries

        private var machine: StateMachine!

        // MARK: Lifecycle

        init() {
            let tsn = States.uninitialized._to(States.initialized)
            tsn.trigger(withInput: .fresh, stateMachine: machine)


//            <Arguments, StateFrom: AnyState, StateTo: State> where StateTo.Arguments == Arguments
//            init(from: StateSlotWithLocalData<StateFrom>, to: StateSlot<Arguments, StateTo>)
        }
        
        // MARK: Internal methods
        
        func initialize() {
            machine.send(Inputs.initialize)
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



