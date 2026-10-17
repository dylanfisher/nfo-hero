import Foundation
import NFOKit
import Testing

@Test func countsLinesAndTheLongestLine() {
    let extent = TextExtent(measuring: "ab\nabcd\nabc")
    #expect(extent == TextExtent(lineCount: 3, longestLine: 4))
}

@Test func endsLinesAtCRLFCRAndLF() {
    #expect(TextExtent(measuring: "ab\r\nabc\rabcd\na") == TextExtent(lineCount: 4, longestLine: 4))
}

@Test func startsAnEmptyLineAfterATrailingLineBreak() {
    #expect(TextExtent(measuring: "abc\r\n") == TextExtent(lineCount: 2, longestLine: 3))
    #expect(TextExtent(measuring: "") == TextExtent(lineCount: 1, longestLine: 0))
}

@Test func countsALetterWithCombiningMarksAsOneColumn() {
    #expect(TextExtent(measuring: "e\u{301}x").longestLine == 2)
}

@Test func countsATabAsFourColumns() {
    #expect(TextExtent(measuring: "a\tb").longestLine == 6)
}

@Test func measuresTheTextOfASceneNFO() throws {
    let extent = try NFO.fixture("scene-cp437.nfo").textExtent
    #expect(extent == TextExtent(lineCount: 3, longestLine: 22))
}

@Test func measuresBBCodeWithoutItsTags() throws {
    let nfo = try NFO.fixture("bbcode-release.nfo")
    #expect(nfo.textExtent == TextExtent(measuring: try nfo.bbcode().text))
    #expect(nfo.textExtent != TextExtent(measuring: nfo.text))
}
