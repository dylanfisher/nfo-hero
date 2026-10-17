import Foundation
import NFOKit
import Testing

@Test func detectsKodiXMLAsMedia() throws {
    let nfo = try NFO.fixture("radarr-movie.nfo")
    #expect(try nfo.mediaItems().map(\.kind) == [.movie])
    #expect(nfo.text.hasPrefix("<?xml"))
}

@Test func detectsXMLAfterLeadingWhitespaceAndBOM() throws {
    let nfo = try NFO.parse(Data("\u{FEFF}\n  <movie><title>X</title></movie>".utf8))
    #expect(try nfo.mediaItems().map(\.title) == ["X"])
    #expect(nfo.text == "\n  <movie><title>X</title></movie>")
}

@Test func readsEveryRootOfAMultiEpisodeFile() throws {
    let items = try NFO.fixture("multi-episode.nfo").mediaItems()
    #expect(items.map(\.title) == ["Pilot (1)", "Pilot (2)"])
    #expect(items.map(\.episode) == [1, 2])
}

@Test func ignoresAURLLineAfterTheXML() throws {
    let nfo = try NFO.fixture("trailing-url.nfo")
    #expect(try nfo.mediaItems().map(\.title) == ["Jurassic Park"])
    #expect(nfo.text.contains("themoviedb.org"))
}

@Test func showsUnknownXMLRootsRaw() throws {
    #expect(try NFO.fixture("unknown-root.nfo").kind == .xml)
}

@Test func reportsMalformedXMLInsteadOfThrowing() throws {
    let nfo = try NFO.fixture("malformed.nfo")
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
    let nfo = try NFO.fixture("scene-utf8.nfo")
    #expect(nfo.kind == .scene)
    #expect(nfo.text.hasPrefix("RELEASE NFO █▓▒░\r\n"))
}

@Test func decodesNonUTF8SceneNFOsAsCP437() throws {
    let nfo = try NFO.fixture("scene-cp437.nfo")
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

@Test func keepsNonASCIITextAroundRemovedDeclarations() throws {
    let text = """
        <?xml version="1.0"?><movie><title>Amélie █</title></movie>
        <?xml version="1.0"?><movie><title>東京物語</title></movie> é
        """
    #expect(try NFO.parse(Data(text.utf8)).mediaItems().map(\.title) == ["Amélie █", "東京物語"])
}
