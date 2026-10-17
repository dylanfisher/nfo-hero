import Foundation

/// An opened NFO file: its text and what kind of NFO it is.
public struct NFO: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        /// Kodi-schema XML. Holds one item per recognized root element, in file order, so a
        /// multi-episode file has several.
        case media([MediaItem])
        /// Well-formed XML with no Kodi root element. Show it raw.
        case xml
        /// Starts with `<` but does not parse. Show it raw along with the error.
        case malformedXML(XMLParseError)
        /// Plain text, usually release-group ASCII art. Show it monospaced and unwrapped.
        case scene
    }

    /// Thrown when a file that starts with `<` is not valid UTF-8. Kodi XML is always UTF-8.
    public struct InvalidUTF8Error: Error, Sendable, Equatable {}

    /// The decoded file, without a UTF-8 BOM. For XML this is the source, including anything
    /// after the last element.
    public let text: String
    public let kind: Kind

    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])

    /// Detects the kind from the first non-whitespace character: `<` means XML, decoded as
    /// UTF-8. Anything else is a scene NFO, decoded as UTF-8 when valid and CP437 otherwise.
    ///
    /// Malformed XML does not throw; it comes back as ``Kind/malformedXML(_:)``.
    public static func parse(_ data: Data) throws -> NFO {
        let body = data.starts(with: byteOrderMark) ? Data(data.dropFirst(3)) : data
        let firstCharacter = body.first { !isASCIIWhitespace($0) }

        guard firstCharacter == UInt8(ascii: "<") else {
            let text = try String(data: body, encoding: .utf8) ?? CP437.decode(body)
            return NFO(text: text, kind: .scene)
        }

        guard let text = String(data: body, encoding: .utf8) else {
            throw InvalidUTF8Error()
        }
        do {
            let roots = try XMLTreeBuilder.roots(of: text)
            let items = roots.compactMap(MediaItem.init(element:))
            return NFO(text: text, kind: items.isEmpty ? .xml : .media(items))
        } catch {
            return NFO(text: text, kind: .malformedXML(error))
        }
    }

    private static func isASCIIWhitespace(_ byte: UInt8) -> Bool {
        byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
    }
}
