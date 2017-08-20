import XCTest
@testable import Stated

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
