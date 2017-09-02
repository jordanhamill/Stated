public class StateTransition<Arguments, StateFrom, StateTo: State> where StateTo.Arguments == Arguments {
    let from: ErasedStateSlot<StateFrom>
    let map: (StateFrom) -> StateTo.MappedState
    let to: StateSlot<Arguments, StateTo>

    init(from: ErasedStateSlot<StateFrom>, to: StateSlot<Arguments, StateTo>, map: @escaping (StateFrom) -> StateTo.MappedState) {
        self.from = from
        self.to = to
        self.map = map
    }

    func trigger(withInput arguments: Arguments, stateMachine: StateMachine) -> (fromState: StateFrom, toState: StateTo) {
        let previousState = stateMachine.currentState as! StateFrom
        let nextState = StateTo.create(arguments: arguments, state: map(previousState))
        stateMachine.setNextState(state: nextState)

        return (previousState, nextState)
    }
}
