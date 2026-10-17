import SwiftUI

extension FocusedValues {
    /// Whether the key window shows its NFO as raw text instead of info cards. Nil when the key
    /// window has no cards, which disables View → Show Raw.
    var showRaw: Binding<Bool>? {
        get { self[ShowRawKey.self] }
        set { self[ShowRawKey.self] = newValue }
    }

    private struct ShowRawKey: FocusedValueKey {
        typealias Value = Binding<Bool>
    }
}
