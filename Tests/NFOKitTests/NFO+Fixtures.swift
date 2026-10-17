import Foundation
import NFOKit
import Testing

private struct NotMediaError: Error {
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
        guard case .media(let items) = kind else { throw NotMediaError(kind: kind) }
        return items
    }
}
