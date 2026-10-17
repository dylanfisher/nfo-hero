/// One entry of `<ratings>`, or the plain `<rating>` when there is no `<ratings>`.
public struct Rating: Sendable, Equatable {
    /// The source, such as `imdb` or `themoviedb`. Nil for a plain `<rating>`.
    public var name: String?
    public var value: Double
    /// The top of the scale. Nil when the file does not say; Kodi then assumes 10.
    public var max: Double?
    public var votes: Int?
    public var isDefault: Bool

    public init(name: String?, value: Double, max: Double?, votes: Int?, isDefault: Bool) {
        self.name = name
        self.value = value
        self.max = max
        self.votes = votes
        self.isDefault = isDefault
    }
}
