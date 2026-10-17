import SwiftUI

/// View → Show Raw (⌥⌘U), which acts on the key window.
struct ShowRawCommands: Commands {
    @FocusedValue(\.showRaw) private var showRaw

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Toggle("Show Raw", isOn: showRaw?.isOn ?? .constant(false))
                .keyboardShortcut("u", modifiers: [.command, .option])
                .disabled(showRaw == nil)
        }
    }
}
