import Foundation

/// Parses XML into `XMLTreeElement`s with `XMLParser`.
final class XMLTreeBuilder: NSObject, XMLParserDelegate {
    private static let wrapperName = "nfo-hero-root"

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
        var body = text.replacing(/<\?xml[^>]*\?>/, with: "")
        if let lastClose = body.lastIndex(of: ">") {
            body = String(body[...lastClose])
        }
        // No newline after the opening tag, so parser line numbers match `text`.
        let opening = "<\(wrapperName)>"
        let wrapped = "\(opening)\(body)</\(wrapperName)>"

        let parser = XMLParser(data: Data(wrapped.utf8))
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

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
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
