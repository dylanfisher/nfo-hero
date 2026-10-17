import AppKit
import NFOKit
import NFOUI
import SwiftUI

@main
struct NFOHeroApp: App {
    var body: some Scene {
        DocumentGroup(viewing: NFODocument.self) { file in
            NFOWindowView(document: file.document, fileURL: file.fileURL)
        }
        .defaultWindowPlacement { content, context in
            // The placement's size is the window's frame, so the title bar is added to the
            // content's ideal size, which the views report from the parsed file.
            let titleBar = NSWindow.frameRect(
                forContentRect: .zero, styleMask: [.titled, .closable, .miniaturizable, .resizable]
            ).size
            let content = content.sizeThatFits(.unspecified)
            let ideal = CGSize(
                width: content.width + titleBar.width, height: content.height + titleBar.height)
            let size = WindowSize.opening(
                ideal: ideal, visible: context.defaultDisplay.visibleRect.size)
            return WindowPlacement(size: size)
        }
        .commands {
            ShowRawCommands()
            TextEncodingCommands()
        }
    }
}
