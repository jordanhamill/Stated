import XCTest
@testable import Stated

class InputArgsAndMappedStateTests: XCTestCase {

    // MARK: Dummy business domain objects

    struct Account {
        let name: String
    }

    enum LaunchedFrom {
        case fresh
        case url(URL)
    }

    enum DeepLink {
        case viewPost
        case friendRequest
    }

    // MARK: Dummy business logic state machine

    class AppLauncher {

        // MARK: States

        public struct UninitializedState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct InitializedState: StateTakingInput {
            typealias MappedState = Void
            typealias Arguments = LaunchedFrom

            let deepLink: DeepLink?

            static func create(arguments: LaunchedFrom) -> InitializedState {
                let deepLink: DeepLink?
                switch arguments {
                case .fresh:
                    deepLink = nil
                case .url:
                    deepLink = DeepLink.viewPost
                }
                return InitializedState(deepLink: deepLink)
            }
        }

        struct LoggedInState: State {
            typealias MappedState = DeepLink?
            typealias Arguments = Account

            let deepLink: DeepLink?
            let account: Account

            static func create(arguments: Account, state: DeepLink?) -> LoggedInState {
                return LoggedInState(deepLink: state, account: arguments)
            }
        }
        
        public struct LoggedOutState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct States {
            static let uninitialized = UninitializedState.slot
            static let initialized = InitializedState.slot
            static let loggedIn = LoggedInState.slot
            static let loggedOut = LoggedOutState.slot
        }

        struct Inputs {
            static let initialize = input("initialize", taking: LaunchedFrom.self)
            static let logIn = input("logIn", taking: Account.self)
            static let logOut = input("logOut")
        }

        // MARK: Private propteries

        var machine: StateMachine!

        // MARK: Lifecycle
        init(logOutOnceLoggedIn: Bool, accountName: String) {
            let mappings: [AnyStateTransitionTrigger] = [
                Inputs.initialize
                    .given(States.uninitialized)
                    .transition(to: States.initialized)
                    .performingSideEffect { (stateMachine: StateMachine) in
                        let account = Account(name: accountName)
                        stateMachine.send(Inputs.logIn.withArgs(account))
                    },

                Inputs.logIn
                    .given(States.initialized)
                    .transition(with: { previousState in return previousState.deepLink })
                    .to(States.loggedIn)
                    .performingSideEffect { (stateMachine: StateMachine) in
                        if logOutOnceLoggedIn {
                            stateMachine.send(Inputs.logOut)
                        }
                    },

                Inputs.logOut
                    .given(States.loggedIn)
                    .transition(to: States.loggedOut)
            ]

            machine = StateMachine(initialState: UninitializedState(), mappings: mappings)
        }

        // MARK: Internal methods

        func initialize(from: LaunchedFrom) {
            machine.send(Inputs.initialize.withArgs(from))
        }
    }

    func testInitalState() {
        let appLauncher = AppLauncher(logOutOnceLoggedIn: false, accountName: "")
        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.uninitialized)
        }
    }

    func testFinalStateWhenLoggedIn() {
        let appLauncher = AppLauncher(logOutOnceLoggedIn: false, accountName: "")
        appLauncher.initialize(from: .fresh)

        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.loggedIn)
        }
    }

    func testFinalStateWhenLoggedOut() {
        let appLauncher = AppLauncher(logOutOnceLoggedIn: true, accountName: "")
        appLauncher.initialize(from: .fresh)

        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.loggedOut)
        }
    }

    func testLocalStateReceivesInputArgumentsWhenLoggedInFromFresh() {
        let appLauncher = AppLauncher(logOutOnceLoggedIn: false, accountName: "Testing name")
        appLauncher.initialize(from: .fresh)

        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.loggedIn)
            let state = currentState.localState as! AppLauncher.LoggedInState
            XCTAssertEqual(state.account.name, "Testing name")
            XCTAssertNil(state.deepLink)
        }
    }

    func testLocalStateIsMappedAndForwardedWhenLoggedInFromUrl() {
        let appLauncher = AppLauncher(logOutOnceLoggedIn: false, accountName: "Another name")
        appLauncher.initialize(from: .url(URL(fileURLWithPath: "")))

        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.loggedIn)
            let state = currentState.localState as! AppLauncher.LoggedInState
            XCTAssertEqual(state.account.name, "Another name")
            XCTAssertEqual(state.deepLink, .viewPost)
        }
    }
}
