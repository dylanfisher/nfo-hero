import Foundation
import NFOKit
import Testing

/// "Café" in Windows-1252, which is not valid UTF-8.
private let windows1252 = Data([0x43, 0x61, 0x66, 0xE9])

@Test func detectsCP437ForTextThatIsNotUTF8() throws {
    let nfo = try NFO.parse(windows1252)
    #expect(nfo.encoding == .cp437)
    #expect(nfo.text == "CafΘ")
}

@Test func detectsUTF8() throws {
    #expect(try NFO.fixture("scene-utf8.nfo").encoding == .utf8)
}

@Test func decodesWithAChosenEncoding() throws {
    let nfo = try NFO.parse(windows1252, encoding: .windows1252)
    #expect(nfo.encoding == .windows1252)
    #expect(nfo.text == "Café")
}

@Test func decodesBytesWindows1252LeavesUndefined() throws {
    #expect(try NFO.parse(Data([0x41, 0x81, 0x80]), encoding: .windows1252).text == "A\u{81}€")
}

@Test func replacesInvalidBytesWhenUTF8IsChosen() throws {
    #expect(try NFO.parse(windows1252, encoding: .utf8).text == "Caf\u{FFFD}")
}

@Test func decodesCP437ControlGlyphsWhenChosen() throws {
    #expect(try NFO.parse(Data("A\u{1}".utf8), encoding: .cp437).text == "A☺")
}

@Test func keepsXMLAsUTF8WhateverEncodingIsChosen() throws {
    let nfo = try NFO.parse(Data("<movie><title>Amélie</title></movie>".utf8), encoding: .cp437)
    #expect(nfo.encoding == .utf8)
    #expect(try nfo.mediaItems().map(\.title) == ["Amélie"])
}
