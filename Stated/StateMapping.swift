import Foundation

public struct StateMapping<State, Arguments> {
    let inputMatches: (Arguments) -> Bool
    let transition: StateTransition<State>

    fileprivate init(inputCondition: @escaping (Arguments) -> Bool, transition: StateTransition<State>) {
        self.inputMatches = inputCondition
        self.transition = transition
    }
}

public struct StateMappingWithEffect<State, Arguments> {
    public typealias SendFunc = (Arguments) -> Void
    public typealias Effect = (Arguments, @escaping SendFunc) -> Void
    public typealias EffectWithoutInput = (@escaping SendFunc) -> Void

    let mapping: StateMapping<State, Arguments>
    let effect: Effect

    fileprivate init(mapping: StateMapping<State, Arguments>, effect: @escaping Effect) {
        self.mapping = mapping
        self.effect = effect
    }
}

// Arguments with from and to state mapping

public func | <State, Arguments: Equatable>(Arguments: Arguments, transition: StateTransition<State>) -> StateMapping<State, Arguments> {
    return { $0 == Arguments } | transition
}

public func | <State, Arguments>(condition: @escaping (Arguments) -> Bool, transition: StateTransition<State>) -> StateMapping<State, Arguments> {
    return StateMapping(inputCondition: condition, transition: transition)
}

// Mapping + effect

public func | <State, Arguments>(mapping: StateMapping<State, Arguments>, effect: @escaping StateMappingWithEffect<State, Arguments>.Effect) -> StateMappingWithEffect<State, Arguments> {
    return StateMappingWithEffect(mapping: mapping, effect: effect)
}

public func | <State, Arguments>(mapping: StateMapping<State, Arguments>, effect: @escaping StateMappingWithEffect<State, Arguments>.EffectWithoutInput) -> StateMappingWithEffect<State, Arguments> {
    return StateMappingWithEffect(mapping: mapping, effect: { _, send in effect(send) })
}
