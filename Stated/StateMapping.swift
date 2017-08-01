import Foundation

public struct StateMapping<State, Input> {
    let inputMatches: (Input) -> Bool
    let transition: StateTransition<State>

    fileprivate init(inputCondition: @escaping (Input) -> Bool, transition: StateTransition<State>) {
        self.inputMatches = inputCondition
        self.transition = transition
    }
}

public struct StateMappingWithEffect<State, Input> {
    public typealias SendFunc = (Input) -> Void
    public typealias Effect = (Input, @escaping SendFunc) -> Void
    public typealias EffectWithoutInput = (@escaping SendFunc) -> Void

    let mapping: StateMapping<State, Input>
    let effect: Effect

    fileprivate init(mapping: StateMapping<State, Input>, effect: @escaping Effect) {
        self.mapping = mapping
        self.effect = effect
    }
}

// Input with from and to state mapping

public func | <State, Input: Equatable>(input: Input, transition: StateTransition<State>) -> StateMapping<State, Input> {
    return { $0 == input } | transition
}

public func | <State, Input>(condition: @escaping (Input) -> Bool, transition: StateTransition<State>) -> StateMapping<State, Input> {
    return StateMapping(inputCondition: condition, transition: transition)
}

// Mapping + effect

public func | <State, Input>(mapping: StateMapping<State, Input>, effect: @escaping StateMappingWithEffect<State, Input>.Effect) -> StateMappingWithEffect<State, Input> {
    return StateMappingWithEffect(mapping: mapping, effect: effect)
}

public func | <State, Input>(mapping: StateMapping<State, Input>, effect: @escaping StateMappingWithEffect<State, Input>.EffectWithoutInput) -> StateMappingWithEffect<State, Input> {
    return StateMappingWithEffect(mapping: mapping, effect: { _, send in effect(send) })
}
