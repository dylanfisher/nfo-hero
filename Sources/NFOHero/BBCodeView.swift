import NFOKit
import SwiftUI

/// A scene NFO with its BBCode drawn as bold, italic, underlined and colored text, or its source
/// when View → Show Raw is on.
struct BBCodeView: View {
    let source: String
    let bbcode: BBCodeText

    @SceneStorage("showRaw") private var showRaw = false

    var body: some View {
        Group {
            if showRaw {
                NFOTextView(text: source)
            } else {
                NFOTextView(text: bbcode.text, runs: bbcode.runs)
            }
        }
        .focusedSceneValue(\.showRaw, ShowRawToggle($showRaw))
    }
}
