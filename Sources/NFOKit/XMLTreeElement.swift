import Foundation

/// An XML element with its text and children, built by `XMLTreeBuilder`.
struct XMLTreeElement: Equatable {
    let name: String
    let attributes: [String: String]
    var text = ""
    var children: [XMLTreeElement] = []

    init(name: String, attributes: [String: String] = [:]) {
        self.name = name
        self.attributes = attributes
    }

    func children(named name: String) -> [XMLTreeElement] {
        children.filter { $0.name == name }
    }

    func child(named name: String) -> XMLTreeElement? {
        children.first { $0.name == name }
    }

    /// The trimmed text of the first child called `name`. Nil when missing or blank, because
    /// Radarr and Sonarr write empty elements like `<tagline />` for unknown fields.
    func string(_ name: String) -> String? {
        child(named: name)?.trimmedText
    }

    /// The trimmed, non-blank texts of every child called `name`.
    func strings(_ name: String) -> [String] {
        children(named: name).compactMap(\.trimmedText)
    }

    /// The text without surrounding whitespace or bidirectional embedding, override and isolate
    /// controls. An override left open in one field reverses the rest of the line the card joins
    /// it into, such as the genres after the certification, so a file could make the card read
    /// differently from its contents. The raw view keeps them.
    var trimmedText: String? {
        var scalars = text.unicodeScalars
        scalars.removeAll { Self.bidiControls.contains($0) }
        let trimmed = String(scalars).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static let bidiControls = CharacterSet(charactersIn: "\u{202A}"..."\u{202E}")
        .union(CharacterSet(charactersIn: "\u{2066}"..."\u{2069}"))
}
