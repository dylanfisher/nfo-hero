import Foundation

/// A scene NFO's text with its BBCode tags removed, and the styles the tags applied.
///
/// Release NFOs are often written to be pasted into tracker posts, so they carry tags such as
/// `[b]`, `[color=#3774F6]` and `[url=…][img]…[/img][/url]`. Only well-formed pairs of known
/// tags are converted. Unknown tags, unmatched or mis-nested tags and the brackets in ASCII art
/// stay in the text as written.
public struct BBCodeText: Sendable, Equatable {
    public struct Style: Sendable, Hashable {
        public var isBold = false
        public var isItalic = false
        public var isUnderlined = false
        /// Nil for the text view's own color.
        public var color: SRGBColor?

        public init(
            isBold: Bool = false, isItalic: Bool = false, isUnderlined: Bool = false,
            color: SRGBColor? = nil
        ) {
            self.isBold = isBold
            self.isItalic = isItalic
            self.isUnderlined = isUnderlined
            self.color = color
        }
    }

    /// A stretch of ``text`` drawn in one style. Text outside every run is plain.
    public struct Run: Sendable, Equatable {
        /// In UTF-16 code units, as `NSString` and `NSAttributedString` count.
        public var range: NSRange
        public var style: Style

        public init(range: NSRange, style: Style) {
            self.range = range
            self.style = style
        }
    }

    public let text: String
    /// In text order, not overlapping, and never plain.
    public let runs: [Run]

    /// Converts the BBCode in `source`. Nil when `source` has no well-formed tag pair, so the
    /// NFO is plain text.
    public init?(parsing source: String) {
        guard let (text, runs) = BBCodeParser.parse(source) else { return nil }
        self.text = text
        self.runs = runs
    }
}
