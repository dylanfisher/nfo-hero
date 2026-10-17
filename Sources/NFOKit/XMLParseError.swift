/// Why an XML NFO failed to parse, as reported by `XMLParser`.
public struct XMLParseError: Error, Sendable, Equatable, CustomStringConvertible {
    /// 1-based line in ``NFO/text``.
    public let line: Int
    public let column: Int
    public let message: String

    public init(line: Int, column: Int, message: String) {
        self.line = line
        self.column = column
        self.message = message
    }

    public var description: String { "line \(line), column \(column): \(message)" }
}
