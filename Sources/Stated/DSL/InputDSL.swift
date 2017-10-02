///
/// Sugar for creating an input with no arguments.
///
public func input(_ friendlyName: String? = nil) -> InputSlot<Void> {
    return InputSlot(friendlyName)
}

///
/// Sugar for creating an input with arguments.
/// Alternative to using `InputSlot<Int>("Input's debug name")`
///
public func input<Arguments>(_ friendlyName: String? = nil, taking: Arguments.Type) -> InputSlot<Arguments> {
    return InputSlot(friendlyName)
}
