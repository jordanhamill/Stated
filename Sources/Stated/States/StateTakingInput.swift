///
///
///
public protocol StateTakingInput: State where MappedState == Void {
    static func create(arguments: Arguments) -> Self
}

extension StateTakingInput {
    public static func create(arguments: Arguments, state: Void) -> Self {
        return self.create(arguments: arguments)
    }
}
