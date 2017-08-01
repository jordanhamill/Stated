import Foundation

public enum TransitionResult<State, Input> {
    case success(old: State, new: State, input: Input)
    case failure(currentState: State, input: Input)
}

public class StateMachine<State, Input> {

    public typealias StateMapping = StateMappingWithEffect<State, Input>
    public typealias StateMapResult = (state: State, effect: StateMappingWithEffect<State, Input>.Effect)?

    // MARK: Public properties

    public private(set) var currentState: State
    public var onTransition: ((TransitionResult<State, Input>) -> Void)?

    // MARK: Private properties

    private let stateMapping: (State, Input) -> StateMapResult
    private let lock = NSRecursiveLock()

    // MARK: Object lifecycle

    public convenience init(initialState: State, mappings: [StateMapping]) {
        let reduced: (State, Input) -> StateMapResult = { currentState, input in
            for mappingWithEffect in mappings {
                let mapping = mappingWithEffect.mapping
                if mapping.inputMatches(input) && mapping.transition.currentStateMatches(currentState) {
                    return (mapping.transition.nextState, mappingWithEffect.effect)
                }
            }

            return nil
        }
        self.init(initialState: initialState, stateMapping: reduced)
    }

    public init(initialState: State, stateMapping: @escaping (State, Input) -> StateMapResult) {
        self.currentState = initialState
        self.stateMapping = stateMapping
    }

    // MARK: Public methods

    public func send(input: Input) {
        lock.lock(); defer { lock.unlock() }

        let currentState = self.currentState
        guard let nextState = stateMapping(currentState, input) else {
            if let onTransition = onTransition {
                onTransition(.failure(currentState: currentState, input: input))
            } else {
                fatalError("Invalid state transition. Current state: \(currentState) with input: \(input)")
            }
            return
        }

        self.currentState = nextState.0
        onTransition?(.success(old: currentState, new: nextState.0, input: input))
        nextState.effect(input, self.send)
    }
}
