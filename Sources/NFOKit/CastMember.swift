/// An `<actor>`.
public struct CastMember: Sendable, Equatable {
    public var name: String
    public var role: String?

    public init(name: String, role: String?) {
        self.name = name
        self.role = role
    }
}
