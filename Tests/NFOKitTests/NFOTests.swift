import Foundation
import NFOKit
import Testing

private func fixture(_ name: String) throws -> NFO {
    let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil))
    return try NFO.parse(Data(contentsOf: url))
}

private func mediaItems(_ nfo: NFO) throws -> [MediaItem] {
    guard case .media(let items) = nfo.kind else {
        Issue.record("expected media, got \(nfo.kind)")
        return []
    }
    return items
}

@Test func detectsKodiXMLAsMedia() throws {
    let nfo = try fixture("radarr-movie.nfo")
    #expect(try mediaItems(nfo).map(\.kind) == [.movie])
    #expect(nfo.text.hasPrefix("<?xml"))
}

@Test func detectsXMLAfterLeadingWhitespaceAndBOM() throws {
    let nfo = try NFO.parse(Data("\u{FEFF}\n  <movie><title>X</title></movie>".utf8))
    #expect(try mediaItems(nfo).map(\.title) == ["X"])
    #expect(nfo.text == "\n  <movie><title>X</title></movie>")
}

@Test func readsEveryRootOfAMultiEpisodeFile() throws {
    let items = try mediaItems(fixture("multi-episode.nfo"))
    #expect(items.map(\.title) == ["Pilot (1)", "Pilot (2)"])
    #expect(items.map(\.episode) == [1, 2])
}

@Test func ignoresAURLLineAfterTheXML() throws {
    let nfo = try fixture("trailing-url.nfo")
    #expect(try mediaItems(nfo).map(\.title) == ["Jurassic Park"])
    #expect(nfo.text.contains("themoviedb.org"))
}

@Test func showsUnknownXMLRootsRaw() throws {
    #expect(try fixture("unknown-root.nfo").kind == .xml)
}

@Test func reportsMalformedXMLInsteadOfThrowing() throws {
    let nfo = try fixture("malformed.nfo")
    guard case .malformedXML(let error) = nfo.kind else {
        Issue.record("expected malformedXML, got \(nfo.kind)")
        return
    }
    #expect(error.line == 4)
    #expect(error.message.contains("mismatch"))
    #expect(nfo.text.contains("</yr>"))
}

@Test func throwsOnXMLThatIsNotUTF8() {
    #expect(throws: NFO.InvalidUTF8Error.self) {
        try NFO.parse(Data([0x3C, 0x6D, 0x3E, 0xFF, 0x3C, 0x2F, 0x6D, 0x3E]))
    }
}

@Test func decodesUTF8SceneNFOs() throws {
    let nfo = try fixture("scene-utf8.nfo")
    #expect(nfo.kind == .scene)
    #expect(nfo.text.hasPrefix("RELEASE NFO █▓▒░\r\n"))
}

@Test func decodesNonUTF8SceneNFOsAsCP437() throws {
    let nfo = try fixture("scene-cp437.nfo")
    #expect(nfo.kind == .scene)
    #expect(nfo.text == "   ██▓▒░ EXAMPLE ░▒▓██\r\n   ╔══╗\r\n")
}

@Test func reportsParseErrorColumnsWithinTheFile() throws {
    guard case .malformedXML(let error) = try NFO.parse(Data("<movie>&</movie>".utf8)).kind else {
        Issue.record("expected malformedXML")
        return
    }
    #expect(error.line == 1)
    #expect(error.column == 9)
}
