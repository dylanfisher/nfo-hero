import NFOKit
import SwiftUI

/// Picks the view for the NFO's kind: info cards for media-server XML, text for the rest.
public struct NFODocumentView: View {
    let nfo: NFO
    /// Nil for a document that has no file, which a viewer never opens in practice.
    let fileURL: URL?

    public init(nfo: NFO, fileURL: URL?) {
        self.nfo = nfo
        self.fileURL = fileURL
    }

    public var body: some View {
        switch nfo.kind {
        case .media(let items):
            MediaView(items: items, text: nfo.text, fileURL: fileURL)
        case .scene(let bbcode?):
            BBCodeView(source: nfo.text, bbcode: bbcode)
        case .xml, .scene(nil):
            NFOTextView(text: nfo.text)
        case .malformedXML(let error):
            VStack(spacing: 0) {
                Label(
                    "Not valid XML: \(error.description)", systemImage: "exclamationmark.triangle"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.15))
                .textSelection(.enabled)
                Divider()
                NFOTextView(text: nfo.text)
            }
        }
    }
}
