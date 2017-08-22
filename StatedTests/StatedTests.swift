import XCTest
@testable import Stated

struct Account {

}

enum LaunchedFrom {
    case fresh
    case url(URL)
}

enum DeepLink {
    case viewPost(String)
    case friendRequest(String)
}

protocol StateWithDeepLink {
    var deepLink: DeepLink? { get }
}

class StatedTests: XCTestCase {
    public struct UninitializedState: SimpleState {
        public typealias Arguments = Void
        public typealias MappedState = Void

        public static func create() -> UninitializedState {
            return UninitializedState()
        }

        init() { }
    }


    struct InitializedState: StateTakingInput, StateWithDeepLink {
        typealias MappedState = Void
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

    struct IndexingState: StateUsingMappedState, StateWithDeepLink  {
        typealias MappedState = DeepLink?
        typealias Arguments = Void

        let deepLink: DeepLink?

        static func create(state: DeepLink?) -> StatedTests.IndexingState {
            return IndexingState(deepLink: state)
        }

        private init(deepLink: DeepLink?) {
            self.deepLink = deepLink
        }
    }

    struct LoggedInState: State, StateWithDeepLink {
        typealias MappedState = DeepLink?
        typealias Arguments = Account

        let deepLink: DeepLink?
        let account: Account

        static func create(arguments: Account, state: DeepLink?) -> StatedTests.LoggedInState {
            return LoggedInState(account: arguments, deepLink: state)
        }

        private init(account: Account, deepLink: DeepLink?) {
            self.account = account
            self.deepLink = deepLink
        }
    }

    struct LoggedOutState: SimpleState {
        typealias MappedState = Void
        typealias Arguments = Void

        static func create() -> LoggedOutState {
            return LoggedOutState()
        }
    }

    class AppLauncher {
        struct States {
            static let uninitialized = UninitializedState.slot
            static let initialized = InitializedState.slot
            static let indexing = IndexingState.slot
            static let loggedIn = LoggedInState.slot
            static let loggedOut = LoggedOutState.slot
        }

        struct Inputs {
            static let initialize = input("initialize", taking: LaunchedFrom.self)
            static let upgrade = input("upgrade")
            static let indexDatabase = input("indexDatabase")
            static let logIn = input("logIn", taking: Account.self)
            static let logOut = input("logOut")
        }

        // MARK: Private propteries
        var machine: StateMachine!

        // MARK: Lifecycle
        init() {
            func passDeepLink(_ state: StateWithDeepLink) -> DeepLink? {
                return state.deepLink
            }

            func initialize(machine: StateMachine, input: SentInput<LaunchedFrom>, from: UninitializedState, to: InitializedState) -> Void {

            }

            let _: [AnyStateTransitionTrigger] = [
                Inputs.initialize
                    .given(States.uninitialized)
                    .transition(to: States.initialized),
                Inputs.indexDatabase.given(States.initialized).transition(with: { $0.deepLink }).to(States.indexing),
                Inputs.logIn.given(States.indexing).transition(with: { $0.deepLink }).to(States.loggedIn),
                Inputs.logIn.given(States.initialized).transition(with: { $0.deepLink }).to(States.loggedIn),
                Inputs.logOut.given(States.loggedIn).transition(to: States.loggedOut)
            ]

            let _: [AnyStateTransitionTrigger] = [
                Inputs.initialize
                    .from(States.uninitialized)
                    .transition(to: States.initialized)
                    .performingSideEffect(initialize),

                Inputs.indexDatabase
                    .from(States.initialized)
                    .passes({ $0.deepLink })
                    .to(States.indexing),

                Inputs.logIn
                    .from(States.indexing)
                    .passes({ $0.deepLink })
                    .to(States.loggedIn),

                Inputs.logIn
                    .from(States.initialized)
                    .passes({ $0.deepLink })
                    .to(States.loggedIn),

                Inputs.logOut
                    .from(States.loggedIn)
                    .transition(to: States.loggedOut)
            ]

            let mappings: [AnyStateTransitionTrigger] = [
                /* Input             |        from          =>    passes    =>        to          | side effect */
                Inputs.initialize    | States.uninitialized                 => States.initialized | initialize,
                Inputs.indexDatabase | States.initialized   => passDeepLink => States.indexing    | { print($0) },
                Inputs.logIn         | States.indexing      => passDeepLink => States.loggedIn    | { print($0) },
                Inputs.logIn         | States.initialized   => passDeepLink => States.loggedIn    | { print($0) },
                Inputs.logOut        | States.loggedIn                      => States.loggedOut   | { print($0) },
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

        appLauncher.machine.send(AppLauncher.Inputs.indexDatabase)
        //        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.indexing)
        appLauncher.machine.send(AppLauncher.Inputs.logIn.withArgs(Account()))
        XCTAssert(appLauncher.machine.currentState == AppLauncher.States.loggedIn)
        
        // todo build composite state machine - can it be formalized as nicely as article
    }
}
