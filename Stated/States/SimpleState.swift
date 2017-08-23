///
///
///
public protocol SimpleState: State {
    typealias Arguments = NoArguments
    typealias MappedState = Void

    init()
}

extension SimpleState {
    public static func create(arguments: NoArguments, state: Void) -> Self {
        return self.init()
    }
}
