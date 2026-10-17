import Foundation

/// How many lines a text has and how long its longest line is, for sizing a window to unwrapped
/// monospaced text without laying it out.
public struct TextExtent: Sendable, Equatable {
    /// Lines as the text view draws them: a trailing line break starts an empty last line, and an
    /// empty text has one line.
    public let lineCount: Int
    /// The longest line, in columns of the monospaced font.
    public let longestLine: Int

    /// A tab counts as this many columns. NSTextView's default tab stops are 28 pt apart, so a tab
    /// advances at most 28 pt, and 4 columns of the 13 pt monospaced font are 32 pt. Counting the
    /// most a tab can take means a line with tabs never measures narrower than it draws.
    static let tabColumns = 4

    public init(lineCount: Int, longestLine: Int) {
        self.lineCount = lineCount
        self.longestLine = longestLine
    }

    /// Counts by Character, so CR, LF and CRLF each end one line, and a letter with combining
    /// marks is one column. Wide characters, such as CJK and emoji, count as one column and
    /// measure narrower than they draw; CP437 has none. A 16 MB file takes about 0.2 s, so this
    /// runs off the main thread, when the file is parsed.
    public init(measuring text: String) {
        var lineCount = 1
        var longestLine = 0
        var column = 0
        for character in text {
            if character.isNewline {
                longestLine = max(longestLine, column)
                column = 0
                lineCount += 1
            } else {
                column += character == "\t" ? Self.tabColumns : 1
            }
        }
        self.init(lineCount: lineCount, longestLine: max(longestLine, column))
    }
}
