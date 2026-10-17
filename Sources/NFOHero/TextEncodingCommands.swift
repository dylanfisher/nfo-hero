import NFOKit
import SwiftUI

/// View → Text Encoding, which acts on the key window: Automatic, naming the detected encoding,
/// or one chosen to decode the file with instead.
struct TextEncodingCommands: Commands {
    @FocusedValue(\.textEncoding) private var choice

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Picker("Text Encoding", selection: choice?.selection ?? .constant(nil)) {
                Text(choice.map { "Automatic (\($0.detected.name))" } ?? "Automatic")
                    .tag(TextEncoding?.none)
                Divider()
                ForEach(TextEncoding.allCases, id: \.self) { encoding in
                    Text(encoding.name).tag(Optional(encoding))
                }
            }
            .disabled(choice == nil)
        }
    }
}
