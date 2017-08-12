import Foundation

public enum TransitionResult<State, Arguments> {
    case success(old: State, new: State, Arguments: Arguments)
    case failure(currentState: State, Arguments: Arguments)
}

public class StateMachine<State, Arguments> {

    public typealias StateMapping = StateMappingWithEffect<State, Arguments>
    public typealias StateMapResult = (state: State, effect: StateMappingWithEffect<State, Arguments>.Effect)?

    // MARK: Public properties

    public private(set) var currentState: State
    public var onTransition: ((TransitionResult<State, Arguments>) -> Void)?

    // MARK: Private properties

    private let stateMapping: (State, Arguments) -> StateMapResult
    private let lock = NSRecursiveLock()

    // MARK: Object lifecycle

    public convenience init(initialState: State, mappings: [StateMapping]) {
        let reduced: (State, Arguments) -> StateMapResult = { currentState, Arguments in
            for mappingWithEffect in mappings {
                let mapping = mappingWithEffect.mapping
                if mapping.inputMatches(Arguments) && mapping.transition.currentStateMatches(currentState) {
                    return (mapping.transition.nextState, mappingWithEffect.effect)
                }
            }

            return nil
        }
        self.init(initialState: initialState, stateMapping: reduced)
    }

    public init(initialState: State, stateMapping: @escaping (State, Arguments) -> StateMapResult) {
        self.currentState = initialState
        self.stateMapping = stateMapping
    }

    // MARK: Public methods

    public func send(Arguments: Arguments) {
        lock.lock(); defer { lock.unlock() }

        let currentState = self.currentState
        guard let nextState = stateMapping(currentState, Arguments) else {
            if let onTransition = onTransition {
                onTransition(.failure(currentState: currentState, Arguments: Arguments))
            } else {
                fatalError("Invalid state transition. Current state: \(currentState) with Arguments: \(Arguments)")
            }
            return
        }

        self.currentState = nextState.0
        onTransition?(.success(old: currentState, new: nextState.0, Arguments: Arguments))
        nextState.effect(Arguments, self.send)
    }
}
