import Foundation

/// Finds artwork that media managers save beside an NFO.
public enum Artwork {
    private static let extensions = ["jpg", "jpeg", "png"]

    /// The first of `<name>-poster`, `poster`, `folder` and `cover` with a `.jpg`, `.jpeg` or
    /// `.png` extension in the NFO's folder, where `<name>` is the NFO's filename without its
    /// extension. Matching ignores case.
    ///
    /// Throws when the folder cannot be listed, which in a sandbox means the app was not granted
    /// access to it.
    public static func poster(nextTo nfoURL: URL, fileManager: FileManager = .default) throws
        -> URL?
    {
        try find(
            ["\(baseName(of: nfoURL))-poster", "poster", "folder", "cover"], nextTo: nfoURL,
            fileManager)
    }

    /// Like ``poster(nextTo:fileManager:)``, for `<name>-fanart` and `fanart`.
    public static func fanart(nextTo nfoURL: URL, fileManager: FileManager = .default) throws
        -> URL?
    {
        try find(["\(baseName(of: nfoURL))-fanart", "fanart"], nextTo: nfoURL, fileManager)
    }

    private static func baseName(of url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    private static func find(
        _ names: [String], nextTo nfoURL: URL, _ fileManager: FileManager
    ) throws -> URL? {
        let folder = nfoURL.deletingLastPathComponent()
        let files = try fileManager.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil
        )
        var byName: [String: URL] = [:]
        for file in files {
            byName[file.lastPathComponent.lowercased()] = file
        }
        for name in names {
            for ext in extensions {
                if let match = byName["\(name).\(ext)".lowercased()] { return match }
            }
        }
        return nil
    }
}
