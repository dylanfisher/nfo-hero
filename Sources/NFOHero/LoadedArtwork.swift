import CoreGraphics
import Foundation
import ImageIO
import NFOKit
import UniformTypeIdentifiers
import os

/// The poster and fanart beside an NFO, decoded and downsampled for display.
struct LoadedArtwork: Sendable {
    var poster: CGImage?
    var fanart: CGImage?

    static let none = LoadedArtwork()

    /// ImageIO decodes by content, not by extension, so a downloaded poster.jpg could reach any of
    /// its decoders. Artwork only looks for these two, and anything else is not a real poster.
    private static let decodableTypes: Set<String> = [
        UTType.jpeg.identifier, UTType.png.identifier,
    ]

    private static let logger: Logger = {
        guard let subsystem = Bundle.main.bundleIdentifier else {
            fatalError("Info.plist has no bundle ID. Launch the bundled app with ./scripts/dev.")
        }
        return Logger(subsystem: subsystem, category: "artwork")
    }()

    /// Finds and decodes the artwork off the main thread. Library posters are often several
    /// thousand pixels tall, so they are downsampled rather than decoded at full size.
    ///
    /// Failures are logged and leave the image out instead of showing an error: artwork is
    /// optional, the card is complete without it, and an unreadable folder or image is not
    /// something the user opened the file to see. `log stream --predicate 'category == "artwork"'`
    /// shows them. Paths and errors are private, because file names in a media library say what
    /// the user watches, and the unified log is readable by admin users and goes into
    /// sysdiagnose reports.
    static func load(nextTo nfoURL: URL) async -> LoadedArtwork {
        await Task.detached(priority: .userInitiated) {
            let artwork: Artwork
            do {
                artwork = try Artwork(nextTo: nfoURL)
            } catch {
                logger.error("Could not look for artwork: \(error, privacy: .private)")
                return .none
            }
            return LoadedArtwork(
                poster: artwork.poster.flatMap { image(at: $0, maxPixels: 1200) },
                fanart: artwork.fanart.flatMap { image(at: $0, maxPixels: 640) }
            )
        }.value
    }

    private static func image(at url: URL, maxPixels: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            logger.error("Could not read \(url.path, privacy: .private)")
            return nil
        }
        // CGImageSourceCreateWithURL only reads enough to tell the type; decoding happens below.
        guard let type = CGImageSourceGetType(source) as String?, decodableTypes.contains(type)
        else {
            logger.error("Not a JPEG or PNG: \(url.path, privacy: .private)")
            return nil
        }
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            logger.error("Could not decode \(url.path, privacy: .private)")
            return nil
        }
        return image
    }
}
