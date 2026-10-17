import NFOKit
import NFOUI
import SwiftUI

@main
struct NFOHeroApp: App {
    var body: some Scene {
        DocumentGroup(viewing: NFODocument.self) { file in
            NFOWindowView(nfo: file.document.nfo, fileURL: file.fileURL)
        }
        .defaultWindowPlacement { _, context in
            WindowPlacement(
                size: WindowSize.portrait(fitting: context.defaultDisplay.visibleRect.size))
        }
        .commands {
            ShowRawCommands()
        }
    }
}
