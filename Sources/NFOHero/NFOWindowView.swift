import NFOKit
import NFOUI
import SwiftUI
import os

/// A document window's content, holding the window's View → Show Raw and View → Text Encoding
/// state. The state lives here rather than in the shared views because `@SceneStorage` works only
/// in an app's scenes, and the Quick Look extension shows the same views without one.
struct NFOWindowView: View {
    let document: NFODocument
    /// Nil for a document that has no file, which a viewer never opens in practice.
    let fileURL: URL?

    @SceneStorage("showRaw") private var showRaw = false
    /// A ``TextEncoding`` raw value, or empty for the detected encoding.
    @SceneStorage("textEncoding") private var encodingName = ""
    // State as a plain property rather than `@State`, which does not build with the Command Line
    // Tools; see MediaView.
    /// The document decoded with the chosen encoding. Nil shows the document as opened.
    private let decoded: State<NFO?>

    private static let logger: Logger = {
        guard let subsystem = Bundle.main.bundleIdentifier else {
            fatalError("The app bundle has no identifier. Launch it with ./scripts/dev.")
        }
        return Logger(subsystem: subsystem, category: "encoding")
    }()

    init(document: NFODocument, fileURL: URL?) {
        self.document = document
        self.fileURL = fileURL
        decoded = State(initialValue: nil)
    }

    private var chosenEncoding: Binding<TextEncoding?> {
        Binding(
            get: { TextEncoding(rawValue: encodingName) },
            set: { encodingName = $0?.rawValue ?? "" })
    }

    var body: some View {
        NFODocumentView(
            nfo: decoded.wrappedValue ?? document.nfo, fileURL: fileURL, showRaw: $showRaw
        )
        .focusedSceneValue(\.textEncoding, textEncodingChoice)
        .task(id: encodingName) {
            guard let encoding = TextEncoding(rawValue: encodingName),
                encoding != document.nfo.encoding
            else {
                decoded.wrappedValue = nil
                return
            }
            let data = document.data
            do {
                // Off the main thread, like the first parse: measuring a 16 MB file takes 0.2 s.
                let nfo = try await Task.detached(priority: .userInitiated) {
                    try NFO.parse(data, encoding: encoding)
                }.value
                guard !Task.isCancelled else { return }
                decoded.wrappedValue = nfo
            } catch {
                // The file parsed when it opened, and only the scene NFOs this applies to are
                // decoded again, which does not throw. The window keeps the detected encoding.
                Self.logger.error(
                    "Decoding as \(encoding.rawValue, privacy: .public) failed: \(error, privacy: .public)"
                )
            }
        }
    }

    /// Nil, which disables the menu, for XML, which is always UTF-8.
    private var textEncodingChoice: TextEncodingChoice? {
        guard case .scene = document.nfo.kind else { return nil }
        return TextEncodingChoice(chosenEncoding, detected: document.nfo.encoding)
    }
}
