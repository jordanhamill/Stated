# Stated
A simple state machine implementation with an API shamelessly based upon [RxAutomaton](https://github.com/inamiy/RxAutomaton).

State transitions cause effects that can send a new input to the state machine, errors can be represented by new states and inputs.
Each state conforms to one of `State`, `SimpleState`, `StateTakingInput` or `StateUsingMappedState`. A state object can receive arguments from a defined input. It can also be passed anything from the previous state

## Example State Machine

App delegates can very quickly become a real handful based on the different initial screens that can appear.
Below we have an app that has:
- A Database Migration phase for updating local data.
- A Database Indexing phase that shows a spinner. Useful if your app stores a large amount of local data.
- Logged in state that shows the main `UIViewController`.
- Logged out state that shows a login/signup `UIViewController`.

```swift
import Stated

class AppLauncher {

    // MARK: Create some simple states that hold no data.

    struct UninitializedState: SimpleState { }
    struct InitializedState: SimpleState { }
    struct UpgradingState: SimpleState { }
    struct IndexingState: SimpleState { }
    struct LoggedInState: SimpleState { }
    struct LoggedOutState: SimpleState { }

    // MARK: Define the states we're going to use by creating "slots" in which the system can place a given instance of one of our states

    struct States {
        static let uninitialized = UninitializedState.slot
        static let initialized = InitializedState.slot
        static let upgrading = UpgradingState.slot
        static let indexing = IndexingState.slot
        static let loggedIn = LoggedInState.slot
        static let loggedOut = LoggedOutState.slot
    }

    // MARK: Define inputs that will be used to trigger transitions between the above states

    struct Inputs {
        static let initialize = input()
        static let upgrade = input()
        static let indexDatabase = input()
        static let logIn = input()
        static let logOut = input()
    }

    // MARK: Private propteries

    private var machine: StateMachine!

    // MARK: Lifecycle

    init(upgradeService: Upgrade, apiService: APIService, db: PersistenceService, rootViewController: RootViewController) {

        // MARK: Side Effects

        func initialize(stateMachine: StateMachine) {
            if upgradeService.isUpgradePending {
                stateMachine.send(Inputs.upgrade)
            } else {
                stateMachine.send(Inputs.indexDatabase)
            }
        }

        func upgrade(stateMachine: StateMachine) {
            rootViewController.showUpgradeProgressController(onCompletion: {
                stateMachine.send(Inputs.indexDatabase)
            })
        }

        func indexDatabase(stateMachine: StateMachine) {
            db.createSecondaryIndices(onCompletion: {
                if apiService.canLogIn {
                    stateMachine.send(Inputs.logIn)
                } else {
                    stateMachine.send(Inputs.logOut)
                }
            })
        }

        func logIn(stateMachine: StateMachine) {
            rootViewController.showLoggedInExperience(apiService: apiService, db: db, onLogOut: {
                stateMachine.send(Inputs.logOut)
            })
        }

        func logOut(stateMachine: StateMachine) {
            rootViewController.showLogInViewController(onLoggedIn: {
                stateMachine.send(Inputs.logIn)
            })
        }

        // MARK: Define state machine using the inputs, slots and side effects from above

        // This is the long-form syntax and is exactly equivalent to the operator syntax below
        let mappings: [AnyStateTransitionTrigger] = [
            Inputs.initialize
                .given(States.uninitialized)
                .transition(to: States.initialized)
                .performingSideEffect(initialize),

            Inputs.upgrade
                .given(States.initialized)
                .transition(to: States.upgrading)
                .performingSideEffect(upgrade),

            Inputs.indexDatabase
                .given(States.upgrading)
                .transition(to: States.indexing)
                .performingSideEffect(indexDatabase),
            Inputs.indexDatabase
                .given(States.initialized)
                .transition(to: States.indexing)
                .performingSideEffect(indexDatabase),

            Inputs.logIn
                .given(States.indexing)
                .transition(to: States.loggedIn)
                .performingSideEffect(logIn),
            Inputs.logIn
                .given(States.loggedOut)
                .transition(to: States.loggedIn)
                .performingSideEffect(logIn),

            Inputs.logOut
                .given(States.indexing)
                .transition(to: States.loggedOut),
                .performingSideEffect(logOut)
            Inputs.logOut
                .given(States.loggedIn)
                .transition(to: States.loggedOut)
                .performingSideEffect(logOut)
        ]

        // This is the shorter operator syntax and is exactly equivalent to the syntax above.
        // It is very easy to visualize how the system should behave in this case
        let mappings: [AnyStateTransitionTrigger] = [
            /* Input             |        from          =>        to          | side effect */
            Inputs.initialize    | States.uninitialized => States.initialized | initialize,

            Inputs.upgrade       | States.initialized   => States.upgrading   | upgrade,

            Inputs.indexDatabase | States.upgrading     => States.indexing    | indexDatabase,
            Inputs.indexDatabase | States.initialized   => States.indexing    | indexDatabase,

            Inputs.logIn         | States.indexing      => States.loggedIn    | logIn,

            Inputs.logOut        | States.indexing      => States.loggedOut   | logOut,
            Inputs.logOut        | States.loggedIn      => States.loggedOut   | logOut,
        ]
        machine = StateMachine(initialState: UninitializedState(), mappings: mappings)
    }

    // MARK: Internal methods

    func initialize() {
        machine.send(Inputs.initialize)
    }
}
```

## Installation

### Cocoapods

Add Stated to your Podfile:
```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Stated'
end
```

Run the following command:
```
$ pod install
```

### Carthage

Add Stated to your Cartfile:
```
github "jordanhamill/Stated"
```

Run the following command:
```
$ carthage update
```
