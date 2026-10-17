import SwiftUI

@main
struct NFOHeroApp: App {
    var body: some Scene {
        DocumentGroup(viewing: NFODocument.self) { file in
            NFOTextView(text: file.document.text)
        }
    }
}
