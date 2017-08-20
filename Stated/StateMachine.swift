import Foundation

//public enum TransitionResult<State, Input> {
//    case success(old: State, new: State, input: Input)
//    case failure(currentState: State, input: Input)
//}

public typealias StateMachineInput = (StateMachine) -> Void
public class StateMachine {
    public struct CurrentState: Equatable {
        let stateId: String
        public let localState: Any

        public static func ==(lhs: CurrentState, rhs: CurrentState) -> Bool {
            return lhs.stateId == rhs.stateId
        }
    }

    let mappings: [ErasedStateTransitionTrigger]
    let inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]]
    private(set) var currentState: CurrentState

    public init<InitialState: State>(initialState: InitialState, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = CurrentState(stateId: initialState.stateId, localState: initialState)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    public func send(_ input: StateMachineInput) {
        input(self)
    }

    public func send(_ input: InputSlot<Void>) {
        input.withArgs(())(self)
    }

    func setNextState(state: CurrentState) {
        currentState = state
    }
}
