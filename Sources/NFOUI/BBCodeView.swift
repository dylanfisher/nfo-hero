import NFOKit
import SwiftUI

/// A scene NFO with its BBCode drawn as bold, italic, underlined and colored text, or its source
/// when View → Show Raw is on.
struct BBCodeView: View {
    let source: String
    let bbcode: BBCodeText
    /// Nil where there is no View → Show Raw.
    let showRaw: Binding<Bool>?

    var body: some View {
        Group {
            if showRaw?.wrappedValue == true {
                NFOTextView(text: source)
            } else {
                NFOTextView(text: bbcode.text, runs: bbcode.runs)
            }
        }
        .focusedSceneValue(\.showRaw, showRaw.map(ShowRawToggle.init))
    }
}
