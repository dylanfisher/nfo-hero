import Foundation

/// Names for the language codes in `<streamdetails>`.
enum LanguageNames {
    /// The names of the languages in `code`, such as `["English"]` for `eng`. Radarr writes one
    /// `<language>` for all of a file's audio streams with the codes run together, as in
    /// `engengfre`, so a code that is not one language is read as 3-letter codes, each named once.
    /// A code with no name is returned as written.
    static func names(for code: String, locale: Locale) -> [String] {
        if let name = locale.localizedString(forLanguageCode: code) {
            return [name]
        }
        guard code.count > 3, code.count.isMultiple(of: 3) else { return [code] }
        var names: [String] = []
        var rest = Substring(code)
        while !rest.isEmpty {
            guard let name = locale.localizedString(forLanguageCode: String(rest.prefix(3))) else {
                return [code]
            }
            if !names.contains(name) {
                names.append(name)
            }
            rest = rest.dropFirst(3)
        }
        return names
    }
}
