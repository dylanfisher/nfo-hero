import Foundation

/// Parses XML into `XMLTreeElement`s with `XMLParser`.
final class XMLTreeBuilder: NSObject, XMLParserDelegate {
    private static let wrapperName = "nfo-hero-root"
    // No newline after the opening tag, so parser line numbers match `text`.
    private static let opening = "<\(wrapperName)>"
    private static let closing = "</\(wrapperName)>"
    /// Deeper input is reported as malformed. Kodi NFOs nest about five levels, but the finished
    /// tree is freed recursively, so a file nested a few thousand deep overflows the stack and
    /// crashes the app. 256 is libxml2's own default limit.
    private static let maxDepth = 256

    private var stack: [XMLTreeElement] = []
    private var root: XMLTreeElement?
    private var firstError: XMLParseError?

    /// The top-level elements of `text`.
    ///
    /// Kodi NFOs are not always one XML document. Multi-episode files concatenate several
    /// `<episodedetails>` roots, each of which may carry its own `<?xml ...?>` declaration, and
    /// Kodi allows a scraper URL on a line after the XML. So declarations are removed, anything
    /// after the last `>` is dropped, and the rest is wrapped in a synthetic root.
    static func roots(of text: String) throws(XMLParseError) -> [XMLTreeElement] {
        let parser = XMLParser(data: wrappedBody(of: text))
        let builder = XMLTreeBuilder()
        parser.delegate = builder
        guard parser.parse(), let root = builder.root else {
            // The first error carries libxml2's message and position. By the time parse()
            // returns, the parser has moved on and reports a generic code.
            let error =
                builder.firstError
                ?? XMLParseError(
                    line: parser.lineNumber, column: parser.columnNumber,
                    message:
                        "XMLParser error \(parser.parserError.map { ($0 as NSError).code } ?? 0)")
            guard error.line == 1 else { throw error }
            throw XMLParseError(
                line: 1, column: error.column - opening.count, message: error.message)
        }
        return root.children
    }

    /// `text` as UTF-8 inside the synthetic root, without `<?xml ...?>` declarations or anything
    /// after the last `>`.
    ///
    /// Scans bytes because a regex took half the parse time of a 5 MB file. Every byte it looks
    /// for is ASCII, and in UTF-8 an ASCII byte is never part of a multi-byte character.
    private static func wrappedBody(of text: String) -> Data {
        let lessThan = UInt8(ascii: "<")
        let greaterThan = UInt8(ascii: ">")
        let declarationStart = Array("<?xml".utf8)
        var text = text
        return text.withUTF8 { source in
            var data = Data(capacity: opening.utf8.count + source.count + closing.utf8.count)
            data.append(contentsOf: opening.utf8)
            var copyFrom = 0
            var searchFrom = 0
            while let start = source[searchFrom...].firstIndex(of: lessThan) {
                searchFrom = start + 1
                guard source[start...].starts(with: declarationStart) else { continue }
                let nameEnd = start + declarationStart.count
                // With no `>` left, no later declaration can be closed either.
                guard let close = source[nameEnd...].firstIndex(of: greaterThan) else { break }
                // `<?xml>` is not a declaration; the `?` must come after the name.
                guard close > nameEnd, source[close - 1] == UInt8(ascii: "?") else { continue }
                data.append(UnsafeBufferPointer(rebasing: source[copyFrom..<start]))
                copyFrom = close + 1
                searchFrom = close + 1
            }
            data.append(UnsafeBufferPointer(rebasing: source[copyFrom...]))
            if let lastClose = data[opening.utf8.count...].lastIndex(of: greaterThan) {
                data.removeSubrange((lastClose + 1)...)
            }
            data.append(contentsOf: closing.utf8)
            return data
        }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        guard stack.count < Self.maxDepth else {
            firstError = XMLParseError(
                line: parser.lineNumber, column: parser.columnNumber,
                message: "Elements are nested more than \(Self.maxDepth) deep")
            parser.abortParsing()
            return
        }
        stack.append(XMLTreeElement(name: elementName, attributes: attributes))
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: any Error) {
        guard firstError == nil else { return }
        let info = (parseError as NSError).userInfo
        firstError = XMLParseError(
            line: info["NSXMLParserErrorLineNumber"] as? Int ?? parser.lineNumber,
            column: info["NSXMLParserErrorColumn"] as? Int ?? parser.columnNumber,
            message: (info["NSXMLParserErrorMessage"] as? String ?? parseError.localizedDescription)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard !stack.isEmpty else { return }
        stack[stack.count - 1].text += string
    }

    func parser(_ parser: XMLParser, foundCDATA block: Data) {
        guard !stack.isEmpty else { return }
        stack[stack.count - 1].text += String(decoding: block, as: UTF8.self)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let element = stack.removeLast()
        if stack.isEmpty {
            root = element
        } else {
            stack[stack.count - 1].children.append(element)
        }
    }
}
