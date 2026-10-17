import Foundation
import NFOKit
import Testing

private let nfoName = "Jurassic Park (1993) [Remux-2160p] {tmdb=329}"

/// A temporary folder holding the NFO and `files`, removed when `body` returns.
private func folder(with files: [String], _ body: (URL) throws -> Void) throws {
    let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    for file in files + ["\(nfoName).mkv", "\(nfoName).nfo"] {
        try Data().write(to: folder.appendingPathComponent(file))
    }
    try body(folder.appendingPathComponent("\(nfoName).nfo"))
}

@Test func findsPosterAndFanartInARadarrFolder() throws {
    try folder(with: ["poster.jpg", "fanart.jpg"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "poster.jpg")
        #expect(try Artwork.fanart(nextTo: nfo)?.lastPathComponent == "fanart.jpg")
    }
}

@Test func prefersThePosterNamedAfterTheNFO() throws {
    try folder(with: ["cover.jpg", "folder.jpg", "poster.png", "\(nfoName)-poster.jpg"]) {
        nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "\(nfoName)-poster.jpg")
    }
}

@Test func prefersPosterThenFolderThenCover() throws {
    try folder(with: ["cover.jpg", "folder.jpg", "poster.png"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "poster.png")
    }
    try folder(with: ["cover.jpg", "folder.jpg"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "folder.jpg")
    }
    try folder(with: ["cover.jpeg"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "cover.jpeg")
    }
}

@Test func matchesNamesIgnoringCase() throws {
    try folder(with: ["Folder.JPG", "\(nfoName.uppercased())-FANART.PNG"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo)?.lastPathComponent == "Folder.JPG")
        #expect(
            try Artwork.fanart(nextTo: nfo)?.lastPathComponent
                == "\(nfoName.uppercased())-FANART.PNG"
        )
    }
}

@Test func returnsNilWithoutArtwork() throws {
    try folder(with: ["poster.webp", "banner.jpg"]) { nfo throws in
        #expect(try Artwork.poster(nextTo: nfo) == nil)
        #expect(try Artwork.fanart(nextTo: nfo) == nil)
    }
}

@Test func throwsWhenTheFolderIsMissing() {
    let nfo = URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)/movie.nfo")
    #expect(throws: (any Error).self) { try Artwork.poster(nextTo: nfo) }
}
