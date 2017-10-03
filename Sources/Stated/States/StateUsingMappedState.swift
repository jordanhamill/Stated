///
///
///
public protocol StateUsingMappedState: State where Arguments == NoArguments {
    static func create(state: MappedState) -> Self
}

extension StateUsingMappedState {
    public static func create(arguments: NoArguments, state: MappedState) -> Self {
        return self.create(state: state)
    }
}
