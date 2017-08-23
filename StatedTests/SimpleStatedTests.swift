import XCTest
@testable import Stated

class SimpleStatedTests: XCTestCase {
    class AppLauncher {

        struct UninitializedState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct InitializedState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct UpgradingState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct IndexingState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct LoggedInState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct LoggedOutState: SimpleState {
            public typealias Arguments = Void
            public typealias MappedState = Void
        }

        struct States {
            static let uninitialized = UninitializedState.slot
            static let initialized = InitializedState.slot
            static let upgrading = UpgradingState.slot
            static let indexing = IndexingState.slot
            static let loggedIn = LoggedInState.slot
            static let loggedOut = LoggedOutState.slot
        }

        struct Inputs {
            static let initialize = input()
            static let upgrade = input()
            static let indexDatabase = input()
            static let logIn = input()
            static let logOut = input()
        }

        // MARK: Private propteries

        var machine: StateMachine!

        // MARK: Lifecycle

        init(isUpgradePending: Bool, canLogIn: Bool) {
            func initialize(stateMachine: StateMachine) {
                if isUpgradePending {
                    stateMachine.send(Inputs.upgrade)
                } else {
                    stateMachine.send(Inputs.indexDatabase)
                }
            }

            func upgrade(stateMachine: StateMachine) {
                stateMachine.send(Inputs.indexDatabase)
            }

            func indexDatabase(stateMachine: StateMachine) {
                if canLogIn {
                    stateMachine.send(Inputs.logIn)
                } else {
                    stateMachine.send(Inputs.logOut)
                }
            }

            func logIn(stateMachine: StateMachine) {
                stateMachine.send(Inputs.logOut)
            }

            let mappings: [AnyStateTransitionTrigger] = [
                /* Input             |        from          =>        to          | side effect */
                Inputs.initialize    | States.uninitialized => States.initialized | initialize,

                Inputs.upgrade       | States.initialized   => States.upgrading   | upgrade,

                Inputs.indexDatabase | States.upgrading     => States.indexing    | indexDatabase,
                Inputs.indexDatabase | States.initialized   => States.indexing    | indexDatabase,

                Inputs.logIn         | States.indexing      => States.loggedIn    | logIn,

                Inputs.logOut        | States.indexing      => States.loggedOut,
                Inputs.logOut        | States.loggedIn      => States.loggedOut,
            ]
            machine = StateMachine(initialState: UninitializedState(), mappings: mappings)
        }

        // MARK: Internal methods

        func initialize() {
            machine.send(Inputs.initialize)
        }
    }

    func testInitalState() {
        let appLauncher = AppLauncher(isUpgradePending: true, canLogIn: true)
        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.uninitialized)
        }
    }

    func testFinalState() {
        let appLauncher = AppLauncher(isUpgradePending: true, canLogIn: true)
        appLauncher.initialize()

        appLauncher.machine.inspectCurrentState { currentState in
            XCTAssert(currentState == AppLauncher.States.loggedOut)
        }
    }

    func testVisitedStatesForUpgradingLoggedIn() {
        let appLauncher = AppLauncher(isUpgradePending: true, canLogIn: true)

        var visitedStateIds: [String] = []
        let expectedStateIds: [String] = [
            AppLauncher.States.initialized.stateId,
            AppLauncher.States.upgrading.stateId,
            AppLauncher.States.indexing.stateId,
            AppLauncher.States.loggedIn.stateId,
            AppLauncher.States.loggedOut.stateId,
        ]

        appLauncher.machine.onTransition = { currentState in
            visitedStateIds.append(currentState.stateId)
        }
        appLauncher.initialize()
        XCTAssertEqual(visitedStateIds, expectedStateIds)
    }

    func testVisitedStatesForUpgradingLoggedOut() {
        let appLauncher = AppLauncher(isUpgradePending: true, canLogIn: false)

        var visitedStateIds: [String] = []
        let expectedStateIds: [String] = [
            AppLauncher.States.initialized.stateId,
            AppLauncher.States.upgrading.stateId,
            AppLauncher.States.indexing.stateId,
            AppLauncher.States.loggedOut.stateId,
        ]

        appLauncher.machine.onTransition = { currentState in
            visitedStateIds.append(currentState.stateId)
        }
        appLauncher.initialize()
        XCTAssertEqual(visitedStateIds, expectedStateIds)
    }

    func testVisitedStatesForNonUpgradeLoggedIn() {
        let appLauncher = AppLauncher(isUpgradePending: false, canLogIn: true)

        var visitedStateIds: [String] = []
        let expectedStateIds: [String] = [
            AppLauncher.States.initialized.stateId,
            AppLauncher.States.indexing.stateId,
            AppLauncher.States.loggedIn.stateId,
            AppLauncher.States.loggedOut.stateId,
        ]

        appLauncher.machine.onTransition = { currentState in
            visitedStateIds.append(currentState.stateId)
        }
        appLauncher.initialize()
        XCTAssertEqual(visitedStateIds, expectedStateIds)
    }

    func testVisitedStatesForNonUpgradeLoggedOut() {
        let appLauncher = AppLauncher(isUpgradePending: false, canLogIn: false)

        var visitedStateIds: [String] = []
        let expectedStateIds: [String] = [
            AppLauncher.States.initialized.stateId,
            AppLauncher.States.indexing.stateId,
            AppLauncher.States.loggedOut.stateId,
        ]

        appLauncher.machine.onTransition = { currentState in
            visitedStateIds.append(currentState.stateId)
        }
        appLauncher.initialize()
        XCTAssertEqual(visitedStateIds, expectedStateIds)
    }
}

