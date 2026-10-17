import CoreGraphics
import Foundation
import ImageIO
import NFOKit
import UniformTypeIdentifiers
import os

/// The poster and fanart beside an NFO, found by name first and then decoded and downsampled for
/// display.
struct LoadedArtwork: Sendable {
    /// One image, from whether the folder has it to whether it decoded.
    enum Slot: Sendable, Equatable {
        /// The folder has no such file. The card leaves no space for it.
        case absent
        /// The file is in the folder and not decoded yet.
        case decoding(URL)
        case decoded(CGImage)
        /// The file is in the folder but is not a JPEG or PNG, or did not decode.
        case failed
    }

    /// The NFO the artwork was found beside.
    let nfoURL: URL
    var poster: Slot
    var fanart: Slot

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

    /// Lists the NFO's folder for artwork without decoding it. It is fast enough to run on the main
    /// thread before the card's first layout, so the card can hold the poster's space from the
    /// start: one listing took 44 ms for a folder of 20,000 files and under 1 ms for a typical
    /// library folder, while decoding a 4000 × 6000 poster took 80–200 ms.
    ///
    /// Failures are logged and leave the image out instead of showing an error: artwork is
    /// optional, the card is complete without it, and an unreadable folder or image is not
    /// something the user opened the file to see. `log stream --predicate 'category == "artwork"'`
    /// shows them. Paths and errors are private, because file names in a media library say what
    /// the user watches, and the unified log is readable by admin users and goes into
    /// sysdiagnose reports.
    static func find(nextTo nfoURL: URL) -> LoadedArtwork {
        do {
            let artwork = try Artwork(nextTo: nfoURL)
            return LoadedArtwork(
                nfoURL: nfoURL,
                poster: artwork.poster.map(Slot.decoding) ?? .absent,
                fanart: artwork.fanart.map(Slot.decoding) ?? .absent
            )
        } catch {
            logger.error("Could not look for artwork: \(error, privacy: .private)")
            return LoadedArtwork(nfoURL: nfoURL, poster: .absent, fanart: .absent)
        }
    }

    /// Decodes the found images off the main thread. Library posters are often several thousand
    /// pixels tall, so they are downsampled rather than decoded at full size.
    func decoded() async -> LoadedArtwork {
        await Task.detached(priority: .userInitiated) { [self] in
            var artwork = self
            artwork.poster = Self.decode(poster, maxPixels: 1200)
            artwork.fanart = Self.decode(fanart, maxPixels: 640)
            return artwork
        }.value
    }

    private static func decode(_ slot: Slot, maxPixels: Int) -> Slot {
        guard case .decoding(let url) = slot else { return slot }
        return image(at: url, maxPixels: maxPixels).map(Slot.decoded) ?? .failed
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
