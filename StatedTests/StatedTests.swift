import XCTest
//import Stated

public protocol StateType: Equatable { }

public struct StateTransition<State: StateType> {
    let from: State
    let to: State
}

infix operator =>: MultiplicationPrecedence
public func =><State: StateType>(from: State, to: State) -> StateTransition<State> {
    return StateTransition(from: from, to: to)
}


public class ErasedStateTransitionTrigger<State: StateType> {

}

public class StateTransitionTrigger<State: StateType, Arguments>: ErasedStateTransitionTrigger<State> {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<State>


    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<State>) {
        self.inputSlot = inputSlot
        self.transition = transition
    }
}

public class StateTransitionTriggerWithSideEffect<State: StateType, Arguments>: StateTransitionTrigger<State, Arguments> {
    public var sideEffect: (InputSlot<Arguments>, State, State, Arguments) -> Void = { _ in }

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<State>, sideEffect: @escaping (InputSlot<Arguments>, State, State, Arguments) -> Void) {
        self.sideEffect = sideEffect
        super.init(inputSlot: inputSlot, transition: transition)
    }
}


public func |<State: StateType, Arguments>(input: InputSlot<Arguments>, transition: StateTransition<State>) -> StateTransitionTrigger<State, Arguments> {
    return StateTransitionTrigger(inputSlot: input, transition: transition)
}

infix operator ~>: AdditionPrecedence
public func |<State: StateType, Arguments>(transitionTrigger: StateTransitionTrigger<State, Arguments>, effect: @escaping (InputSlot<Arguments>, State, State, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<State, Arguments> {
    return StateTransitionTriggerWithSideEffect(inputSlot: transitionTrigger.inputSlot, transition: transitionTrigger.transition, sideEffect: effect)
}

public struct InputSlot<Arguments>: Equatable, Hashable {
    fileprivate let uuid: String

    public init() {
        self.uuid = UUID().uuidString
    }

    public func withArgs<State: StateType>(_ args: Arguments) -> StateMachineInput<State> {
        return { sm in
            for erasedTransitionTrigger in sm.mappings {
                guard let transitionTrigger = erasedTransitionTrigger as? StateTransitionTrigger<State, Arguments> else { continue }
                guard transitionTrigger.inputSlot.uuid == self.uuid else { continue }

                // Found transition for this input
                let currentState = sm.currentState
                guard transitionTrigger.transition.from == currentState else { continue }
                // Found a transition that can execute for this state
                let newState = transitionTrigger.transition.to
                sm.setNextState(state: newState)
                guard let transitionTriggerWithEffect = transitionTrigger as? StateTransitionTriggerWithSideEffect<State, Arguments> else { return }
                transitionTriggerWithEffect.sideEffect(self, currentState, newState, args)
            }
        }
    }

    public static func ==(lhs: InputSlot, rhs: InputSlot) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }
}

public typealias StateMachineInput<State: StateType> = (StateMachine<State>) -> Void
public class StateMachine<State: StateType> {

    fileprivate let mappings: [ErasedStateTransitionTrigger<State>]
    fileprivate var currentState: State

    init(initialState: State, mappings: [ErasedStateTransitionTrigger<State>]) {
        self.currentState = initialState
        self.mappings = mappings
    }

    func send(_ input: StateMachineInput<State>) {
        input(self)
    }

    func setNextState(state: State) {
        currentState = state
    }
}

class StatedTests: XCTestCase {

    enum State: StateType {
        case uninitialized
        case initializing
        case indexingDatabase
        case loggedIn
    }

    var stateMachine: StateMachine<State>!

    override func setUp() {

        struct Inputs {
            static let initialize = InputSlot<Bool>()
            static let indexDatabase = InputSlot<()>()
            static let logIn = InputSlot<String>()
        }

        func initializeThing(input: InputSlot<Bool>, fromState: State, toState: State, offline: Bool) {

        }

        let mappings: [ErasedStateTransitionTrigger<State>] =  [
            // Input          |    from         =>    to           | side effect
            Inputs.initialize |  .uninitialized =>  .initializing  | initializeThing

//            (Inputs.logIn |  .indexingDatabase =>  .loggedIn) ~> initializeThing
        ]

        stateMachine = StateMachine(initialState: .uninitialized, mappings: mappings)

        stateMachine.send(Inputs.initialize.withArgs(true))


        print(mappings)
        print(mappings[0])
    }

    func testExample() {

        XCTAssert(true)
    }
}



