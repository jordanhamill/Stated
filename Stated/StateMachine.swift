import Foundation

public typealias StateMachineInput = (StateMachine) -> Void

public class StateMachine {
    public struct CurrentState: Equatable {
        let stateId: String
        public let localState: Any

        public static func ==(lhs: CurrentState, rhs: CurrentState) -> Bool {
            return lhs.stateId == rhs.stateId
        }
    }

    // MARK: Public

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

    public func send(_ input: StateMachineInput) {
        lock.lock(); defer { lock.unlock() }
        input(self)
    }

    public func send(_ input: InputSlot<Void>) {
        send(input.withArgs(()))
    }

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
