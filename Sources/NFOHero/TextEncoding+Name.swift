import NFOKit

extension TextEncoding {
    /// The name View → Text Encoding lists it by.
    var name: String {
        switch self {
        case .utf8: "UTF-8"
        case .cp437: "DOS (CP437)"
        case .windows1252: "Western (Windows-1252)"
        }
    }
}
