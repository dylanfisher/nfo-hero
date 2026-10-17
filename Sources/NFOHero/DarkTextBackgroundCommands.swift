import NFOUI
import SwiftUI

/// View → Dark Text Background, which applies to every window.
struct DarkTextBackgroundCommands: Commands {
    @AppStorage(DarkTextBackground.defaultsKey) private var isOn = false

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Toggle("Dark Text Background", isOn: $isOn)
        }
    }
}
