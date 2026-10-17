import NFOKit
import SwiftUI

/// Picks the view for the NFO's kind: info cards for media-server XML, text for the rest.
public struct NFODocumentView: View {
    let nfo: NFO
    let fileURL: URL?
    let showRaw: Binding<Bool>?

    /// - Parameters:
    ///   - fileURL: The file, whose folder is searched for artwork. Nil shows cards without
    ///     artwork.
    ///   - showRaw: The window's View → Show Raw state, which info cards and BBCode publish to the
    ///     menu and follow. Nil where there is no menu, such as Quick Look: the cards and the
    ///     drawn BBCode always show, and nothing mentions Show Raw.
    public init(nfo: NFO, fileURL: URL?, showRaw: Binding<Bool>?) {
        self.nfo = nfo
        self.fileURL = fileURL
        self.showRaw = showRaw
    }

    public var body: some View {
        IdealSizeLayout {
            switch nfo.kind {
            case .media(let items):
                MediaView(items: items, text: nfo.text, fileURL: fileURL, showRaw: showRaw)
            case .scene(let bbcode?):
                BBCodeView(
                    source: nfo.text, bbcode: bbcode, extent: nfo.textExtent, showRaw: showRaw)
            case .xml, .scene(nil):
                NFOTextView(text: nfo.text, extent: nfo.textExtent)
            case .malformedXML(let error):
                VStack(spacing: 0) {
                    Label(
                        "Not valid XML: \(error.description)",
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.15))
                    .textSelection(.enabled)
                    Divider()
                    NFOTextView(text: nfo.text, extent: nfo.textExtent)
                }
            }
        }
    }
}
