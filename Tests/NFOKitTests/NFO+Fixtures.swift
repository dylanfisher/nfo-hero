import Foundation
import NFOKit
import Testing

private struct UnexpectedKindError: Error {
    let kind: NFO.Kind
}

extension NFO {
    /// Parses `Fixtures/<name>`.
    static func fixture(_ name: String) throws -> NFO {
        let url = try #require(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil))
        return try parse(Data(contentsOf: url))
    }

    /// The items of a media NFO. Throws for any other kind, so the test stops at the line that
    /// expected media instead of failing every check after it.
    func mediaItems() throws -> [MediaItem] {
        guard case .media(let items) = kind else { throw UnexpectedKindError(kind: kind) }
        return items
    }

    /// The parse error of a malformed XML NFO. Throws for any other kind, like ``mediaItems()``.
    func parseError() throws -> XMLParseError {
        guard case .malformedXML(let error) = kind else { throw UnexpectedKindError(kind: kind) }
        return error
    }

    /// The converted BBCode of a scene NFO. Throws for any other kind or a scene NFO without
    /// BBCode, like ``mediaItems()``.
    func bbcode() throws -> BBCodeText {
        guard case .scene(let bbcode?) = kind else { throw UnexpectedKindError(kind: kind) }
        return bbcode
    }
}
