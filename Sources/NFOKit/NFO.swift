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
        /// Plain text, usually release-group ASCII art. Show it monospaced and unwrapped. Holds
        /// the text with its BBCode converted when the file has any.
        case scene(BBCodeText?)
    }

    /// Thrown when a file that starts with `<` is not valid UTF-8. Kodi XML is always UTF-8.
    public struct InvalidUTF8Error: Error, Sendable, Equatable {}

    /// Thrown for a file larger than ``maxFileSize``.
    public struct FileTooLargeError: LocalizedError, Sendable, Equatable {
        /// Bytes.
        public let size: Int

        public var errorDescription: String? {
            let size = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            let limit = ByteCountFormatter.string(
                fromByteCount: Int64(NFO.maxFileSize), countStyle: .file)
            return "The file is \(size), and NFO Hero opens files up to \(limit)."
        }
    }

    /// The largest file ``parse(_:)`` accepts, in bytes. NFOs are kilobytes. A file of hundreds
    /// of megabytes is not one, and decoding and laying it out takes several times its size in
    /// memory and minutes of CPU.
    public static let maxFileSize = 16_000_000

    /// The decoded file, without a UTF-8 BOM. For XML this is the source, including anything
    /// after the last element.
    public let text: String
    public let kind: Kind
    /// What the text was decoded with. Always UTF-8 for XML.
    public let encoding: TextEncoding
    /// The lines of the text a text view shows for the NFO: the text with its BBCode converted for
    /// a scene NFO that has any, ``text`` otherwise. Measured here because parsing runs off the
    /// main thread, and the window is sized from it before it opens.
    public let textExtent: TextExtent

    private init(text: String, kind: Kind, encoding: TextEncoding) {
        self.text = text
        self.kind = kind
        self.encoding = encoding
        if case .scene(let bbcode?) = kind {
            textExtent = TextExtent(measuring: bbcode.text)
        } else {
            textExtent = TextExtent(measuring: text)
        }
    }

    private static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])

    /// Detects the kind from the first non-whitespace character: `<` means XML, decoded as
    /// UTF-8. Anything else is a scene NFO. Its SAUCE record is dropped, and it is decoded as
    /// UTF-8 when valid and free of controls other than tab, line feed and carriage return, and
    /// as CP437 otherwise, since DOS art draws the controls as glyphs.
    ///
    /// Malformed XML does not throw; it comes back as ``Kind/malformedXML(_:)``.
    ///
    /// - Parameter encoding: Decodes a scene NFO with this instead of detecting its encoding. XML
    ///   is always UTF-8.
    public static func parse(_ data: Data, encoding: TextEncoding? = nil) throws -> NFO {
        guard data.count <= maxFileSize else { throw FileTooLargeError(size: data.count) }
        let body = data.starts(with: byteOrderMark) ? Data(data.dropFirst(3)) : data
        let firstCharacter = body.first { !isASCIIWhitespace($0) }

        guard firstCharacter == UInt8(ascii: "<") else {
            let art = SAUCE.removingTrailer(from: body)
            let encoding =
                encoding
                ?? (art.contains(where: isDOSGlyph) || String(data: art, encoding: .utf8) == nil
                    ? .cp437 : .utf8)
            let text = encoding.decode(art)
            return NFO(text: text, kind: .scene(BBCodeText(parsing: text)), encoding: encoding)
        }

        guard let text = String(data: body, encoding: .utf8) else {
            throw InvalidUTF8Error()
        }
        do {
            let roots = try XMLTreeBuilder.roots(of: text)
            let items = roots.compactMap(MediaItem.init(element:))
            return NFO(text: text, kind: items.isEmpty ? .xml : .media(items), encoding: .utf8)
        } catch {
            return NFO(text: text, kind: .malformedXML(error), encoding: .utf8)
        }
    }

    /// A control byte that only CP437 gives a meaning: DOS draws it as a glyph, and no UTF-8 text
    /// contains it.
    private static func isDOSGlyph(_ byte: UInt8) -> Bool {
        (byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D) || byte == 0x7F
    }

    private static func isASCIIWhitespace(_ byte: UInt8) -> Bool {
        byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
    }
}
