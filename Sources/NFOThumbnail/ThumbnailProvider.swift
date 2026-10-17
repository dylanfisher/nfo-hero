import AppKit
import NFOKit
import NFOUI
import QuickLookThumbnailing

/// Finder's thumbnail of a scene NFO: the top of its art, as the app's text view draws it. XML
/// NFOs get none, so Finder shows the NFO document icon: an info card would need the poster,
/// which the sandbox keeps out of reach, and XML text at icon size is grey lines.
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let thumbnail: NFOThumbnail
        do {
            // Mapped, so a file over the size limit is rejected without reading it.
            let nfo = try NFO.parse(Data(contentsOf: request.fileURL, options: .alwaysMapped))
            guard case .scene = nfo.kind else { throw CocoaError(.featureUnsupported) }
            thumbnail = NFOThumbnail(nfo: nfo)
        } catch {
            // Finder shows the generic icon.
            handler(nil, error)
            return
        }
        let size = thumbnail.size(fitting: request.maximumSize)
        handler(
            QLThumbnailReply(contextSize: size) { thumbnail.draw(in: size) }, nil)
    }
}
