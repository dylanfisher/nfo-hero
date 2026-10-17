import NFOKit
import SwiftUI

/// Picks the view for the NFO's kind: info cards for media-server XML, text for the rest.
struct NFODocumentView: View {
    let nfo: NFO
    /// Nil for a document that has no file, which a viewer never opens in practice.
    let fileURL: URL?

    var body: some View {
        switch nfo.kind {
        case .media(let items):
            MediaView(items: items, text: nfo.text, fileURL: fileURL)
        case .xml, .scene:
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
