import Foundation
import NFOKit
import Testing

private let blue = SRGBColor(red: 0x37, green: 0x74, blue: 0xF6)
private let red = SRGBColor(red: 255, green: 0, blue: 0)

private func parse(_ source: String) throws -> BBCodeText {
    try #require(BBCodeText(parsing: source))
}

private func fixture(_ name: String) throws -> (source: String, bbcode: BBCodeText) {
    let nfo = try NFO.fixture(name)
    return (nfo.text, try nfo.bbcode())
}

/// The text each run covers, with its style.
private func styledText(_ bbcode: BBCodeText) -> [(String, BBCodeText.Style)] {
    bbcode.runs.map { ((bbcode.text as NSString).substring(with: $0.range), $0.style) }
}

@Test func returnsNilForTextWithoutTags() {
    #expect(BBCodeText(parsing: "  ██▓▒░ EXAMPLE ░▒▓██\n") == nil)
}

@Test func drawsColoredBoldHeadings() throws {
    let bbcode = try fixture("bbcode-release.nfo").bbcode
    let headings = styledText(bbcode).filter { $0.1 == .init(isBold: true, color: blue) }
    #expect(
        headings.map(\.0) == ["GENERAL INFO", "VIDEO", "SCREENSHOTS", "GROUP NOTES"])
    #expect(bbcode.text.contains("\nGENERAL INFO\nSOURCE "))
    #expect(bbcode.runs.count == 4)
}

@Test func dropsLinesThatHoldOnlyTags() throws {
    let bbcode = try fixture("bbcode-release.nfo").bbcode
    #expect(bbcode.text.hasPrefix("-----"))
    #expect(bbcode.text.hasSuffix("[/img]\n") == false)
    #expect(bbcode.text.hasSuffix("https://img.example.com/banner.png\n"))
}

@Test func keepsLinesWithoutTagsAsWritten() throws {
    let (source, bbcode) = try fixture("bbcode-release.nfo")
    let untagged = source.split(separator: "\n", omittingEmptySubsequences: false)
        .filter { !$0.contains("[") }
    let lines = Set(bbcode.text.split(separator: "\n", omittingEmptySubsequences: false))
    #expect(untagged.count > 20)
    #expect(untagged.allSatisfy(lines.contains))
}

@Test func showsAnImageLinkAsItsURLOnce() throws {
    let bbcode = try fixture("bbcode-release.nfo").bbcode
    #expect(bbcode.text.contains("\nhttps://img.example.com/1.png https://img.example.com/2.png\n"))
    #expect(!bbcode.text.contains("th.png"))
}

@Test func showsImagesAsTheirURL() throws {
    #expect(
        try parse("see [img]https://a.example/x.png[/img]").text == "see https://a.example/x.png")
    #expect(
        try parse("[IMG=300x200]https://a.example/x.png[/IMG]").text == "https://a.example/x.png")
}

@Test func showsLinkTextWithoutTheTarget() throws {
    #expect(try parse("[url=https://a.example]Site[/url]").text == "Site")
    #expect(try parse("[url]https://a.example[/url]").text == "https://a.example")
    #expect(try parse("[url=https://a.example][b]Site[/b][/url]").text == "Site")
}

@Test func stylesBoldItalicUnderlineAndColor() throws {
    let bbcode = try parse("[b]B[/b] [i]I[/i] [u]U[/u] [color=red]R[/color]")
    #expect(bbcode.text == "B I U R")
    #expect(
        styledText(bbcode).map(\.1) == [
            .init(isBold: true), .init(isItalic: true), .init(isUnderlined: true),
            .init(color: red),
        ])
}

@Test func combinesNestedStyles() throws {
    let bbcode = try parse("[color=#f00][b]x[/b]y[/color]")
    #expect(styledText(bbcode).map(\.0) == ["x", "y"])
    #expect(styledText(bbcode).map(\.1) == [.init(isBold: true, color: red), .init(color: red)])
}

@Test func readsTagsInAnyCase() throws {
    let bbcode = try parse("[B]x[/b] [Color=RED]y[/COLOR]")
    #expect(bbcode.text == "x y")
    #expect(bbcode.runs.count == 2)
}

@Test func acceptsQuotedValues() throws {
    #expect(try parse(#"[color="red"]x[/color]"#).runs.first?.style.color == red)
    #expect(try parse("[url='https://a.example'][img]t[/img][/url]").text == "https://a.example")
}

@Test func removesLayoutTagsAndKeepsTheirContent() throws {
    let source = """
        [size=4]a[/size][font=Courier New]b[/font][center]c[/center][quote]d[/quote]\
        [quote=Bob]e[/quote][code]f[/code][spoiler]g[/spoiler][spoiler=Plot]h[/spoiler]\
        [hide]i[/hide][pre]j[/pre]
        """
    let bbcode = try parse(source)
    #expect(bbcode.text == "abcdefghij")
    #expect(bbcode.runs.isEmpty)
}

@Test func keepsBracketsInASCIIArtLiteral() throws {
    let (source, bbcode) = try fixture("bbcode-ascii-brackets.nfo")
    #expect(bbcode.text == source.replacingOccurrences(of: "[b]NOTES[/b]", with: "NOTES"))
    #expect(styledText(bbcode).map(\.0) == ["NOTES"])
}

@Test func leavesMisnestedTagsLiteral() throws {
    let bbcode = try fixture("bbcode-misnested.nfo").bbcode
    #expect(
        bbcode.text == """
            [i]crossed[/i]
            [u]never closed
            stray [/color] closer
            fine

            """)
    #expect(styledText(bbcode).map(\.0) == ["[i]crossed", "fine"])
}

@Test func leavesUnknownAndMalformedTagsLiteral() throws {
    let bbcode = try fixture("bbcode-unknown.nfo").bbcode
    #expect(
        bbcode.text == """
            [list][*]item[/list]
            [s]struck[/s]
            [color=notacolor]x[/color]
            [b=1]x[/b]
            [bold]x[/bold]
            hidden

            """)
}

@Test func keepsTagsWithLineBreaksOrLongValuesLiteral() {
    #expect(BBCodeText(parsing: "[url=a\nb]x[/url]") == nil)
    let long = String(repeating: "a", count: 3000)
    #expect(BBCodeText(parsing: "[url=\(long)]x[/url]") == nil)
}

@Test func measuresRangesInUTF16() throws {
    let bbcode = try parse("😀 é [b]x[/b]")
    #expect(bbcode.runs.first?.range == NSRange(location: 5, length: 1))
}

@Test func dropsTagOnlyLinesWithCRLFBreaks() throws {
    #expect(try parse("[font=X]\r\n|art|\r\n[/font]").text == "|art|\r\n")
}

@Test func mergesAdjacentRunsOfOneStyle() throws {
    let bbcode = try parse(String(repeating: "[b]x[/b]", count: 100_000))
    #expect(
        bbcode.runs == [
            .init(range: NSRange(location: 0, length: 100_000), style: .init(isBold: true))
        ])
}

// Openers past the depth limit stay literal, so hostile nesting cannot grow the style stack.
@Test func boundsNesting() throws {
    let depth = 100_000
    let bbcode = try parse(
        String(repeating: "[b]", count: depth) + "x" + String(repeating: "[/b]", count: depth))
    let literal = depth - 32
    #expect(
        bbcode.text
            == String(repeating: "[b]", count: literal) + "x"
            + String(repeating: "[/b]", count: literal))
    #expect(bbcode.runs.allSatisfy { $0.style == .init(isBold: true) })
}
