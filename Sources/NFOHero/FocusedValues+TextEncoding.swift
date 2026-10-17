import SwiftUI

extension FocusedValues {
    /// The key window's View → Text Encoding state. Nil when the key window shows XML, which
    /// disables the menu.
    var textEncoding: TextEncodingChoice? {
        get { self[TextEncodingKey.self] }
        set { self[TextEncodingKey.self] = newValue }
    }

    private struct TextEncodingKey: FocusedValueKey {
        typealias Value = TextEncodingChoice
    }
}
