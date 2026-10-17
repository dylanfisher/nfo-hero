import Foundation

/// Artwork that media managers save beside an NFO.
public struct Artwork: Sendable, Equatable {
    private static let extensions = ["jpg", "jpeg", "png"]

    /// The first of `<name>-poster`, `poster`, `folder` and `cover` with a `.jpg`, `.jpeg` or
    /// `.png` extension in the NFO's folder, where `<name>` is the NFO's filename without its
    /// extension. Matching ignores case.
    public var poster: URL?
    /// Like ``poster``, for `<name>-fanart` and `fanart`.
    public var fanart: URL?

    /// Finds the poster and fanart in one listing of the NFO's folder, which in a library can
    /// hold thousands of files.
    ///
    /// Throws when the folder cannot be listed, which in a sandbox means the app was not granted
    /// access to it.
    public init(nextTo nfoURL: URL, fileManager: FileManager = .default) throws {
        let baseName = nfoURL.deletingPathExtension().lastPathComponent
        let posterNames = Self.fileNames(["\(baseName)-poster", "poster", "folder", "cover"])
        let fanartNames = Self.fileNames(["\(baseName)-fanart", "fanart"])
        let wanted = Set(posterNames + fanartNames)

        let files = try fileManager.contentsOfDirectory(
            at: nfoURL.deletingLastPathComponent(), includingPropertiesForKeys: nil
        )
        var byName: [String: URL] = [:]
        for file in files {
            let name = file.lastPathComponent.lowercased()
            if wanted.contains(name) { byName[name] = file }
        }
        poster = posterNames.lazy.compactMap { byName[$0] }.first
        fanart = fanartNames.lazy.compactMap { byName[$0] }.first
    }

    /// Every name with every extension, lowercased, in order of preference.
    private static func fileNames(_ names: [String]) -> [String] {
        names.flatMap { name in extensions.map { "\(name).\($0)".lowercased() } }
    }
}
