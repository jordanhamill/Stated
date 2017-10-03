///
///
///
public protocol SimpleState: State where Arguments == NoArguments, MappedState == Void {
    init()
}

extension SimpleState {
    public static func create(arguments: NoArguments, state: Void) -> Self {
        return self.init()
    }
}
