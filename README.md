# Stated
A simple state machine implementation with an API shamelessly based upon [RxAutomaton](https://github.com/inamiy/RxAutomaton).

State transitions cause effects that can send a new input to the state machine, errors can be represented by new states and inputs.

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

    // MARK: States

    enum State {
        case uninitialized
        case initialized
        case upgrading
        case indexing
        case loggedOut
        case loggedIn
    }

    // MARK: Inputs

    enum Input {
        case initialize
        case upgrade
        case indexDatabase
        case logIn
        case logOut
    }

    // MARK: Private propteries

    private var machine: StateMachine<State, Input>!

    // MARK: Lifecycle

    init(upgradeService: Upgrade, apiService: APIService, db: PersistenceService, rootViewController: RootViewController) {

        func canLogIn() -> Bool {
            return !apiService.account.username.isEmpty && apiService.account.hasPassword()
        }

        func initialize(send: @escaping (Input) -> Void) {
            if upgradeService.isUpgradePending() {
                send(.upgrade)
            } else {
                send(.indexDatabase)
            }
        }

        func upgrade(send: @escaping (Input) -> Void) {
            rootViewController.showUpgradeController(upgradeService: upgradeService) {
                // Upgrade successful callback
                send(.indexDatabase)
            }
        }

        func indexDatabase(send: @escaping (Input) -> Void) {
            db.createSecondaryIndices(on: SharedNote.self)

            if canLogIn() {
                send(.logIn)
            } else {
                send(.logOut)
            }
        }

        func logIn(send: @escaping (Input) -> Void) {
            rootViewController.showTourListViewController {
                // Log out callback
                send(.logOut)
            }
        }

        func logOut(send:  @escaping (Input) -> Void) {
            apiService.clearAuthentication()
            rootViewController.showLoginViewController {
                // Login successful callback
                send(.logIn)
            }
        }

        let mappings: [StateMappingWithEffect<State, Input>] = [
            /* Input        |      from             to       |   effect    */
            .initialize     | .uninitialized => .initialized | initialize,

            .upgrade        | .initialized   => .upgrading   | upgrade,

            .indexDatabase  | .initialized   =>  .indexing   | indexDatabase,
            .indexDatabase  | .upgrading     =>  .indexing   | indexDatabase,

            .logIn          | .indexing      => .loggedIn    | logIn,
            .logIn          | .loggedOut     => .loggedIn    | logIn,

            .logOut         | .indexing      => .loggedOut   | logOut,
            .logOut         | .loggedIn      => .loggedOut   | logOut
        ]

        machine = StateMachine<State, Input>(initialState: .uninitialized, mappings: mappings)
    }

    // MARK: Internal methods

    func initialize() {
        machine.send(input: .initialize)
    }
}
```
