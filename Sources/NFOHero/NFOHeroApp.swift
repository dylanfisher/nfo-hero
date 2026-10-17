import NFOUI
import SwiftUI

@main
struct NFOHeroApp: App {
    var body: some Scene {
        DocumentGroup(viewing: NFODocument.self) { file in
            NFODocumentView(nfo: file.document.nfo, fileURL: file.fileURL)
        }
        .commands {
            ShowRawCommands()
        }
    }
}
