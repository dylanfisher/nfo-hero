import AppKit
import NFOKit
import NFOUI
import QuickLookUI
import SwiftUI

/// The Quick Look preview of an NFO: the view the app's window shows, without View → Show Raw.
final class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        view = NSView()
        // With no screen to measure, Quick Look picks the size itself.
        if let screen = NSScreen.main {
            preferredContentSize = WindowSize.portrait(fitting: screen.visibleFrame.size)
        }
    }

    /// Quick Look shows a spinner until this returns, so the file is read and parsed off the main
    /// thread. A file NFO Hero cannot open throws, and Quick Look shows its generic preview.
    func preparePreviewOfFile(at url: URL) async throws {
        let nfo = try await Task.detached(priority: .userInitiated) {
            // Mapped, so a file over the size limit is rejected without reading it.
            try NFO.parse(Data(contentsOf: url, options: .alwaysMapped))
        }.value
        // No file URL, so no artwork: the extension runs in App Sandbox, where Quick Look grants
        // read access to the previewed file but not to its folder, and listing it fails.
        let preview = NSHostingView(
            rootView: NFODocumentView(nfo: nfo, fileURL: nil, showRaw: nil))
        preview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            preview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            preview.topAnchor.constraint(equalTo: view.topAnchor),
            preview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
