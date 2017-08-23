import Foundation

public typealias StateMachineInput = (StateMachine) -> Void

public class StateMachine {
    public struct CurrentState: Equatable, CustomDebugStringConvertible {
        public let stateId: String
        public let localState: Any

        public static func ==(lhs: CurrentState, rhs: CurrentState) -> Bool {
            return lhs.stateId == rhs.stateId
        }

        public var debugDescription: String {
            return "\(stateId) {\(localState)}"
        }
    }

    // MARK: Public

    ///
    /// Triggers when the current state changes
    ///
    public var onTransition: ((CurrentState) -> Void)?

    // MARK: Internal

    let mappings: [AnyStateTransitionTrigger]
    let inputToTransitionTriggers: [String: [AnyStateTransitionTrigger]]
    private(set) var currentState: CurrentState

    // MARK: Private

    private let lock = NSRecursiveLock()

    // MARK: Lifecycle

    public init<InitialState: State>(initialState: InitialState, mappings: [AnyStateTransitionTrigger]) {
        self.currentState = CurrentState(stateId: initialState.stateId, localState: initialState)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [AnyStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    // MARK: Public

    ///
    /// Send an input with arguments to trigger a state change.
    /// - warning: This will `fatalError` if a transition is not defined for the input + current state.
    /// - parameter input: Input with arguments. e.g. `anInput.withArgs(100)`
    ///
    public func send(_ input: StateMachineInput) {
        lock.lock(); defer { lock.unlock() }
        input(self)
    }

    ///
    /// Send an input that does not require arguments to trigger a state change.
    /// - warning: This will `fatalError` if a transition is not defined for the input + current state.
    /// - parameter input: Input without arguments.
    ///
    public func send(_ input: InputSlot<Void>) {
        send(input.withArgs(()))
    }

    ///
    /// Thread safe inspection of the current state of the system.
    /// - parameter inspect: A closure that has access to the current state.
    ///
    public func inspectCurrentState(inspect: (CurrentState) -> Void) {
        lock.lock(); defer { lock.unlock() }
        inspect(currentState)
    }

    // MARK: Internal

    func setNextState(state: CurrentState) {
        lock.lock(); defer { lock.unlock() }
        currentState = state
        onTransition?(currentState)
    }
}
