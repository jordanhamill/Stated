import XCTest
//import Stated

public class StateTransition<InputArgs, LocalStateFrom, LocalStateTo> {
    let from: _IStateSlotWithLocalData<LocalStateFrom>
    let to: IStateSlot<InputArgs, LocalStateFrom, LocalStateTo>

    init(from: _IStateSlotWithLocalData<LocalStateFrom>, to: IStateSlot<InputArgs, LocalStateFrom, LocalStateTo>) {
        self.from = from
        self.to = to
    }

    func trigger(withInput input: InputArgs, stateMachine: StateMachine) {
        let castLocalState = stateMachine.currentState.localState as! LocalStateFrom
        let nextStateLocalState = to.mapInput(input, castLocalState)
        let nextState = StateMachine.State(
            slotUuid: to.uuid,
            localState: nextStateLocalState
        )
        stateMachine.setNextState(state: nextState)
    }
}

infix operator =>: MultiplicationPrecedence
public func =><InputArgs, LocalStateFrom, LocalStateTo>(from: _IStateSlotWithLocalData<LocalStateFrom>, to: IStateSlot<InputArgs, LocalStateFrom, LocalStateTo>) -> StateTransition<InputArgs, LocalStateFrom, LocalStateTo> {
    return from.to(to)
}



public class ErasedStateTransitionTrigger {
    let inputUuid: String
    private let trigger: (Any, StateMachine) -> Bool

    init(inputUuid: String, trigger: @escaping (Any, StateMachine) -> Bool) {
        self.inputUuid = inputUuid
        self.trigger = trigger
    }

    func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        return trigger(args, stateMachine)
    }
}

public class StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo>: ErasedStateTransitionTrigger {
    let inputSlot: InputSlot<Arguments>
    let transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>) {
        self.inputSlot = inputSlot
        self.transition = transition
        super.init(inputUuid: inputSlot.uuid, trigger: { (args: Any, stateMachine: StateMachine) in
            guard stateMachine.currentState.slotUuid == transition.from.uuid else { return false }
            guard let typedArgs = args as? Arguments else { return false }

            transition.trigger(withInput: typedArgs, stateMachine: stateMachine)
            return true
        })
    }
}

public class StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo>: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
    public var sideEffect: (InputSlot<Arguments>, _IStateSlotWithLocalData<LocalStateFrom>, IStateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void = { _ in }

    public init(inputSlot: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>, sideEffect: @escaping (InputSlot<Arguments>, _IStateSlotWithLocalData<LocalStateFrom>, IStateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) {
        self.sideEffect = sideEffect
        super.init(inputSlot: inputSlot, transition: transition)
    }

    override func tryTransition(args: Any, stateMachine: StateMachine) -> Bool {
        let transitioned = super.tryTransition(args: args, stateMachine: stateMachine)
        if transitioned {
            sideEffect(inputSlot, transition.from, transition.to, args as! Arguments)
        }
        return transitioned
    }
}


public func |<Arguments, LocalStateFrom, LocalStateTo>(input: InputSlot<Arguments>, transition: StateTransition<Arguments, LocalStateFrom, LocalStateTo>) -> StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo> {
    return StateTransitionTrigger(inputSlot: input, transition: transition)
}


public func |<Arguments, LocalStateFrom, LocalStateTo>(
    transitionTrigger: StateTransitionTrigger<Arguments, LocalStateFrom, LocalStateTo>,
    effect: @escaping (InputSlot<Arguments>, _IStateSlotWithLocalData<LocalStateFrom>, IStateSlot<Arguments, LocalStateFrom, LocalStateTo>, Arguments) -> Void) -> StateTransitionTriggerWithSideEffect<Arguments, LocalStateFrom, LocalStateTo> {
        return StateTransitionTriggerWithSideEffect(inputSlot: transitionTrigger.inputSlot, transition: transitionTrigger.transition, sideEffect: effect)
}

public struct InputSlot<Arguments>: Equatable, Hashable {
    fileprivate let uuid: String

    public init() {
        self.uuid = UUID().uuidString
    }

    public func withArgs(_ args: Arguments) -> StateMachineInput {
        return { sm in
            guard let potentialTransitions = sm.inputToTransitionTriggers[self.uuid] else { return }

            for erasedTransitionTrigger in potentialTransitions {
                if erasedTransitionTrigger.tryTransition(args: args, stateMachine: sm) {
                    return
                }
            }

            fatalError("Undefined transition")
        }
    }

    public static func ==(lhs: InputSlot, rhs: InputSlot) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public var hashValue: Int {
        return uuid.hashValue
    }
}

public func ==<InputArgs, PreviousLocalState, LocalState>(lhs: StateMachine.State, rhs: IStateSlot<InputArgs, PreviousLocalState, LocalState>) -> Bool {
    return lhs.slotUuid == rhs.uuid
}

public typealias StateMachineInput = (StateMachine) -> Void
public class StateMachine {
    public struct State: Equatable {
        let slotUuid: String
        let localState: Any?

        public static func ==(lhs: State, rhs: State) -> Bool {
            return lhs.slotUuid == rhs.slotUuid
        }
    }

    fileprivate let mappings: [ErasedStateTransitionTrigger]
    fileprivate let inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]]
    fileprivate var currentState: State

    init(initialState: StateSlot, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = State(slotUuid: initialState.uuid, localState: nil)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    init<InputArgs, PreviousLocalState, LocalState>(initialState: IStateSlot<InputArgs, PreviousLocalState, LocalState>, localState: LocalState, mappings: [ErasedStateTransitionTrigger]) {
        self.currentState = State(slotUuid: initialState.uuid, localState: localState)
        self.mappings = mappings

        var inputToTransitionTriggers: [String: [ErasedStateTransitionTrigger]] = [:]
        for transitionTrigger in mappings {
            var triggers = inputToTransitionTriggers[transitionTrigger.inputUuid] ?? []
            triggers.append(transitionTrigger)
            inputToTransitionTriggers[transitionTrigger.inputUuid] = triggers
        }
        self.inputToTransitionTriggers = inputToTransitionTriggers
    }

    func send(_ input: StateMachineInput) {
        input(self)
        print("Done")
    }

    func setNextState(state: State) {
        currentState = state
    }
}

class StatedTests: XCTestCase {

    struct States {
        static let uninitialized = IStateSlot<Void, Void, Void> { (_, _) in
            return
        }
        static let initializing = IStateSlot<Bool, Void, Bool> { input, previousState in
            return input
        }

        static let indexing = IStateSlot<Void, Bool, Void> { _, _ in
            return
        }
    }

    struct Inputs {
        static let initialize = InputSlot<Bool>()
        static let indexDatabase = InputSlot<Void>()
        static let logIn = InputSlot<String>()
    }

    var stateMachine: StateMachine!

    override func setUp() {

        func initializeThing(input: InputSlot<Bool>, fromState: _IStateSlotWithLocalData<Void>, toState: IStateSlot<Bool, Void, Bool>, offline: Bool) {
            print("Side effects bitches")
        }

        func indexStuff(input: InputSlot<Void>, fromState: _IStateSlotWithLocalData<Bool>, toState: IStateSlot<Void, Bool, Void>, _: Void) {
            print("Indexing")
        }

        let mappings: [ErasedStateTransitionTrigger] =  [
            // Input             |    from         =>    to                     | side effect
            Inputs.initialize    |  States.uninitialized => States.initializing | initializeThing,
            Inputs.indexDatabase |  States.initializing  => States.indexing     | indexStuff

//            (Inputs.logIn |  .indexingDatabase =>  .loggedIn) ~> initializeThing
        ]

        let initial = States.uninitialized
        stateMachine = StateMachine(initialState: initial, localState: (), mappings: mappings)

        stateMachine.send(Inputs.initialize.withArgs(true))
    }

    func testExample() {
        XCTAssert(stateMachine.currentState == States.initializing)

        stateMachine.send(Inputs.indexDatabase.withArgs())
        XCTAssert(stateMachine.currentState == States.indexing)
    }
}



