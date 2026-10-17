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

    var trimmedText: String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
