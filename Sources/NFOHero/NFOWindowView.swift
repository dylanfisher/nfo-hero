import NFOKit
import NFOUI
import SwiftUI

/// A document window's content, holding the window's View → Show Raw state. The state lives here
/// rather than in the shared views because `@SceneStorage` works only in an app's scenes, and the
/// Quick Look extension shows the same views without one.
struct NFOWindowView: View {
    let nfo: NFO
    /// Nil for a document that has no file, which a viewer never opens in practice.
    let fileURL: URL?

    @SceneStorage("showRaw") private var showRaw = false

    var body: some View {
        NFODocumentView(nfo: nfo, fileURL: fileURL, showRaw: $showRaw)
    }
}
