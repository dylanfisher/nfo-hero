import Foundation

/// Turns BBCode into text and style runs for ``BBCodeText``.
///
/// Works on UTF-16 code units, which is what `NSRange` counts, in two linear passes: one finds
/// the tags and pairs them, the next copies the text between them. No regex, so a 16 MB file
/// with tens of thousands of brackets costs the same per character as one with none.
enum BBCodeParser {
    /// Openers deeper than this stay literal. Real NFOs nest two or three deep, and the bound
    /// keeps the stack, and the search for a closer's opener, small on hostile input.
    static let maxDepth = 32
    /// Longer `=value`s are not tags. Image URLs in NFOs run to a few hundred characters.
    static let maxValueLength = 2048

    private enum Tag: CaseIterable {
        case bold, italic, underline, color, size, font, center, quote, code, spoiler, hide, pre
        case url, image

        var name: String {
            switch self {
            case .bold: "b"
            case .italic: "i"
            case .underline: "u"
            case .color: "color"
            case .size: "size"
            case .font: "font"
            case .center: "center"
            case .quote: "quote"
            case .code: "code"
            case .spoiler: "spoiler"
            case .hide: "hide"
            case .pre: "pre"
            case .url: "url"
            case .image: "img"
            }
        }

        enum Value { case none, optional, required }

        /// Whether the opening tag takes `=value`, as in `[url=…]` or `[spoiler=Title]`.
        var value: Value {
            switch self {
            case .bold, .italic, .underline, .center, .pre: .none
            case .color, .size, .font: .required
            case .quote, .code, .spoiler, .hide, .url, .image: .optional
            }
        }
    }

    /// The longest tag name, `spoiler`.
    private static let maxNameLength = 7

    /// Tag names packed one lowercase ASCII byte each into an integer, so looking one up
    /// allocates nothing.
    private static let tagsByKey: [UInt64: Tag] = Dictionary(
        uniqueKeysWithValues: Tag.allCases.map { tag in
            (tag.name.utf8.reduce(0) { $0 << 8 | UInt64($1) }, tag)
        })

    private struct Token {
        /// The `[`, in code units of the source.
        var start: Int
        /// After the `]`.
        var end: Int
        var tag: Tag
        var isClosing: Bool
        /// The index of the matching token, or nil while the tag is literal text.
        var partner: Int?
    }

    private static let openBracket = UInt16(UInt8(ascii: "["))
    private static let closeBracket = UInt16(UInt8(ascii: "]"))
    private static let slash = UInt16(UInt8(ascii: "/"))
    private static let equals = UInt16(UInt8(ascii: "="))
    private static let space = UInt16(UInt8(ascii: " "))
    private static let lineFeed = UInt16(UInt8(ascii: "\n"))
    private static let carriageReturn = UInt16(UInt8(ascii: "\r"))

    /// The text without tags and its style runs, or nil when no tag pair converts.
    static func parse(_ source: String) -> (String, [BBCodeText.Run])? {
        let units = Array(source.utf16)
        var tokens = scanTokens(units)
        guard pair(&tokens) else { return nil }
        var emitter = Emitter(units: units)
        emitter.emit(tokens)
        // Foundation's initializer, because `String(decoding:as: UTF16.self)` takes a generic
        // path that spent 0.5 s on 15 MB.
        let text = String(utf16CodeUnits: emitter.output, count: emitter.output.count)
        return (text, emitter.runs)
    }

    // MARK: - Finding tags

    private static func scanTokens(_ units: [UInt16]) -> [Token] {
        var tokens: [Token] = []
        var index = 0
        while let open = units[index...].firstIndex(of: openBracket) {
            if let token = token(in: units, at: open) {
                tokens.append(token)
                index = token.end
            } else {
                index = open + 1
            }
        }
        return tokens
    }

    /// The known, well-formed tag starting at `start`, or nil.
    ///
    /// A value ends at the first `]` and may not contain `[` or a line break, so the scan of a
    /// value never passes the next `[`. That keeps scanning linear.
    private static func token(in units: [UInt16], at start: Int) -> Token? {
        var index = start + 1
        let isClosing = index < units.count && units[index] == slash
        if isClosing { index += 1 }

        var key: UInt64 = 0
        let nameStart = index
        while index < units.count, index - nameStart <= maxNameLength,
            let letter = lowercaseLetter(units[index])
        {
            key = key << 8 | UInt64(letter)
            index += 1
        }
        let nameLength = index - nameStart
        guard nameLength > 0, nameLength <= maxNameLength, let tag = tagsByKey[key],
            index < units.count
        else { return nil }

        if units[index] == closeBracket {
            guard isClosing || tag.value != .required else { return nil }
            return Token(start: start, end: index + 1, tag: tag, isClosing: isClosing)
        }
        guard !isClosing, tag.value != .none, units[index] == equals else { return nil }

        let valueStart = index + 1
        index = valueStart
        while index < units.count, index - valueStart <= maxValueLength {
            let unit = units[index]
            if unit == closeBracket { break }
            if unit == openBracket || unit == lineFeed || unit == carriageReturn { return nil }
            index += 1
        }
        guard index < units.count, units[index] == closeBracket, index > valueStart,
            index - valueStart <= maxValueLength
        else { return nil }
        let token = Token(start: start, end: index + 1, tag: tag, isClosing: false)
        if tag == .color, SRGBColor(bbcodeValue: value(of: token, in: units)) == nil {
            return nil
        }
        return token
    }

    private static func lowercaseLetter(_ unit: UInt16) -> UInt8? {
        guard unit < 0x80 else { return nil }
        let lower = UInt8(unit) | 0x20
        return lower >= UInt8(ascii: "a") && lower <= UInt8(ascii: "z") ? lower : nil
    }

    /// The `=value` of an opening tag, without surrounding quotes. Empty when it has none.
    private static func value(of token: Token, in units: [UInt16]) -> String {
        let valueStart = token.start + 1 + token.tag.name.utf16.count + 1
        guard valueStart < token.end else { return "" }
        var slice = units[valueStart..<(token.end - 1)]
        if slice.count >= 2, let first = slice.first, first == slice.last,
            first == UInt16(UInt8(ascii: "\"")) || first == UInt16(UInt8(ascii: "'"))
        {
            slice = slice.dropFirst().dropLast()
        }
        return String(utf16CodeUnits: Array(slice), count: slice.count)
    }

    // MARK: - Pairing

    /// Links each closing tag to the nearest open tag of the same name. Openers between the
    /// two never close, so they stay literal: in `[b][i]x[/b][/i]` only `b` converts. Returns
    /// whether any pair formed.
    private static func pair(_ tokens: inout [Token]) -> Bool {
        var open: [Int] = []
        var paired = false
        for index in tokens.indices {
            let token = tokens[index]
            guard token.isClosing else {
                if open.count < maxDepth { open.append(index) }
                continue
            }
            guard let depth = open.lastIndex(where: { tokens[$0].tag == token.tag }) else {
                continue
            }
            let opener = open[depth]
            tokens[opener].partner = index
            tokens[index].partner = opener
            open.removeSubrange(depth...)
            paired = true
        }
        return paired
    }

    // MARK: - Writing the text

    private struct Emitter {
        let units: [UInt16]
        var output: [UInt16] = []
        var runs: [BBCodeText.Run] = []
        private var styles = [BBCodeText.Style()]
        /// The next source unit to copy.
        private var position = 0
        /// Where the current line starts in `output`.
        private var lineStart = 0
        /// Whether the current line had a converted tag.
        private var lineHasTag = false
        /// The end in `output` of the last URL written for an `[url=…][img]…[/img][/url]`.
        private var lastLinkEnd: Int?

        init(units: [UInt16]) {
            self.units = units
            output.reserveCapacity(units.count)
        }

        mutating func emit(_ tokens: [Token]) {
            var index = 0
            while index < tokens.count {
                let token = tokens[index]
                guard let partner = token.partner else {
                    // Literal: copied with the text around it.
                    index += 1
                    continue
                }
                copyText(upTo: token.start)
                lineHasTag = true
                if token.isClosing {
                    styles.removeLast()
                } else if let linkEnd = imageLinkEnd(tokens, opener: index, closer: partner) {
                    writeImageLink(BBCodeParser.value(of: token, in: units))
                    position = tokens[linkEnd].end
                    index = linkEnd + 1
                    continue
                } else {
                    styles.append(style(applying: token))
                }
                position = token.end
                index += 1
            }
            copyText(upTo: units.count)
        }

        /// For `[url=X][img]Y[/img][/url]` with nothing between the tags, the index of the
        /// closing `[/url]`. The thumbnail Y is not worth showing next to X.
        private func imageLinkEnd(_ tokens: [Token], opener: Int, closer: Int) -> Int? {
            let url = tokens[opener]
            guard url.tag == .url, url.end - url.start > "[url]".utf16.count,
                opener + 1 < closer
            else { return nil }
            let image = tokens[opener + 1]
            guard image.tag == .image, !image.isClosing, image.start == url.end,
                let imageClose = image.partner, imageClose + 1 == closer,
                tokens[imageClose].end == tokens[closer].start
            else { return nil }
            return closer
        }

        /// Writes the link's URL, with a space after the previous one when they sit side by
        /// side, as screenshot rows do.
        private mutating func writeImageLink(_ url: String) {
            if lastLinkEnd == output.count { append([BBCodeParser.space][...]) }
            append(Array(url.utf16)[...])
            lastLinkEnd = output.count
        }

        private func style(applying token: Token) -> BBCodeText.Style {
            var style = styles[styles.count - 1]
            switch token.tag {
            case .bold: style.isBold = true
            case .italic: style.isItalic = true
            case .underline: style.isUnderlined = true
            case .color:
                style.color = SRGBColor(bbcodeValue: BBCodeParser.value(of: token, in: units))
            case .size, .font, .center, .quote, .code, .spoiler, .hide, .pre, .url, .image: break
            }
            return style
        }

        /// Copies the source up to `end`, leaving out the line break of a line that held only
        /// tags, such as `[font=Courier New]` above the art. Other lines keep their columns.
        private mutating func copyText(upTo end: Int) {
            while position < end {
                var lineEnd = position
                while lineEnd < end, units[lineEnd] != lineFeed, units[lineEnd] != carriageReturn {
                    lineEnd += 1
                }
                append(units[position..<lineEnd])
                position = lineEnd
                guard position < end else { return }
                var breakEnd = position + 1
                if units[position] == carriageReturn, breakEnd < units.count,
                    units[breakEnd] == lineFeed
                {
                    breakEnd += 1
                }
                if !lineHasTag || output.count > lineStart {
                    append(units[position..<breakEnd])
                }
                position = breakEnd
                lineStart = output.count
                lineHasTag = false
            }
        }

        private mutating func append(_ slice: ArraySlice<UInt16>) {
            guard !slice.isEmpty else { return }
            let start = output.count
            output.append(contentsOf: slice)
            let style = styles[styles.count - 1]
            guard style != BBCodeText.Style() else { return }
            if let last = runs.last, last.style == style, NSMaxRange(last.range) == start {
                runs[runs.count - 1].range.length += slice.count
            } else {
                runs.append(
                    BBCodeText.Run(
                        range: NSRange(location: start, length: slice.count), style: style))
            }
        }
    }
}
