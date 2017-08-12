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

public func input() -> InputSlot<Void> {
    return InputSlot()
}

public func input<Arguments>(taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot()
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

    public init<Arguments, PreviousLocalState, LocalState>(initialState: StateSlot<Arguments, PreviousLocalState, LocalState>, localState: LocalState, mappings: [ErasedStateTransitionTrigger]) {
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

    public func send(_ Arguments: StateMachineInput) {
        Arguments(self)
    }

    public func send(_ Arguments: InputSlot<Void>) {
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

    enum LaunchedFrom {
        case fresh
        case url(URL)
    }

    enum DeepLink {
        case viewPost(String)
        case friendRequest(String)
    }

    struct Account {
        let email: String
        var name: String
    }

    class LoggedInState {
        let account: Account

        struct States {
            static let timeline = state()
            static let friends = state()
            static let profile = state()
        }

        struct Inputs {
            static let viewTimeline = input()
            static let viewFriends = input()
            static let viewProfile = input()
        }

        private var machine: StateMachine!

        init(account: Account, deepLink: DeepLink?) {
            self.account = account

            let mappings: [ErasedStateTransitionTrigger] = [
                Inputs.viewTimeline | States.friends  => States.timeline,
                Inputs.viewProfile  | States.friends  => States.profile,

                Inputs.viewProfile  | States.timeline => States.profile,
                Inputs.viewFriends  | States.timeline => States.friends,

                Inputs.viewFriends  | States.profile  => States.friends,
                Inputs.viewTimeline | States.profile  => States.timeline,
            ]

            self.machine = StateMachine(initialState: States.timeline, localState: (), mappings: mappings)

            if let deepLink = deepLink {
                switch deepLink {
                case .viewPost(let postId):
                    machine.send(Inputs.viewTimeline.withArgs(()))
                case .friendRequest(let requestId):
                    machine.send(Inputs.viewFriends.withArgs(()))
                }
            }
        }

    }

    class AppLauncher {
        struct States {
            static let uninitialized = state()
            static let initialized = state() // This now forward on as a composed up state of `FromUrl`/Deep navigation link destination for app
            static let upgrading = state()
            static let indexing = state() // vc state - inject in completion
            static let loggedOut = state()
            static let loggedIn = state() // Pass in Account and store it in state as well as deep link destination - imagine account being manipulated by VCs - create another state machine for an internal tab bar?
        }

        struct Inputs {
            static let initialize = input() // Input FromUrl
            static let upgrade = input()
            static let indexDatabase = input()
            static let logIn = input() // Take in Account
            static let logOut = input()
        }

        // MARK: Private propteries

        private var machine: StateMachine!

        // MARK: Lifecycle

        init() {

            func canLogIn() -> Bool {
                return true
            }

//            func initialize(send: @escaping (Input) -> Void) {
//                if true {
//                    send(.upgrade)
//                } else {
//                    send(.indexDatabase)
//                }
//            }
//
//            func upgrade(send: @escaping (Input) -> Void) {
//                rootViewController.showUpgradeController(upgradeService: upgradeService) {
//                    // Upgrade successful callback
//                    send(.indexDatabase)
//                }
//            }
//
//            func indexDatabase(send: @escaping (Input) -> Void) {
//                db.createSecondaryIndices(on: SharedNote.self)
//
//                if canLogIn() {
//                    send(.logIn)
//                } else {
//                    send(.logOut)
//                }
//            }
//
//            func logIn(send: @escaping (Input) -> Void) {
//                rootViewController.showTourListViewController {
//                    // Log out callback
//                    send(.logOut)
//                }
//            }
//
//            func logOut(send:  @escaping (Input) -> Void) {
//                apiService.clearAuthentication()
//                rootViewController.showLoginViewController {
//                    // Login successful callback
//                    send(.logIn)
//                }
//            }

            let mappings: [ErasedStateTransitionTrigger] = [
                /* Input              |           from             to                 |   effect    */
                Inputs.initialize     | States.uninitialized => States.initialized, //| initialize,

                Inputs.upgrade        | States.initialized   => States.upgrading,   //| upgrade,

                Inputs.indexDatabase  | States.initialized   => States.indexing,    //| indexDatabase,
                Inputs.indexDatabase  | States.upgrading     => States.indexing,    //| indexDatabase,

                Inputs.logIn          | States.indexing      => States.loggedIn,    //| logIn,
                Inputs.logIn          | States.loggedOut     => States.loggedIn,    //| logIn,
                
                Inputs.logOut         | States.indexing      => States.loggedOut,   //| logOut,
                Inputs.logOut         | States.loggedIn      => States.loggedOut    //| logOut
            ]
            
            machine = StateMachine(initialState: States.uninitialized, localState: (), mappings: mappings)
        }
        
        // MARK: Internal methods
        
        func initialize() {
            machine.send(Inputs.initialize)
        }
    }

    var appLauncher: AppLauncher!
    override func setUp() {
        appLauncher = AppLauncher()
        // TODO Make state sig nicer
//        func initializeThing(Arguments: InputSlot<Bool>, fromState: StateSlotWithLocalData<Void>, toState: StateSlot<Bool, Void, Bool>, offline: Bool) {
//            print("Side effects bitches")
//        }
//
//        func indexStuff(Arguments: InputSlot<Void>, fromState: StateSlotWithLocalData<Bool>, toState: StateSlot<Void, Bool, Void>, _: Void) {
//            print("Indexing")
//        }
//
//
//
//        let mappings: [ErasedStateTransitionTrigger] =  [
//            // Input             |          from         =>    to               | side effect
//            Inputs.initialize    |  States.uninitialized => States.initializing | initializeThing,
//            Inputs.indexDatabase |  States.initializing  => States.indexing     | indexStuff,
//
////            Inputs.logIn         |  States.initializing  => States.loggedIn//     | indexStuff
//        ]
//
//        let initial = States.uninitialized
//        stateMachine = StateMachine(initialState: initial, localState: (), mappings: mappings)
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



