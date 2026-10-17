import SwiftUI

extension FocusedValues {
    /// Whether the key window shows its NFO as raw text instead of info cards or rendered BBCode.
    /// Nil when the key window has neither, which disables View → Show Raw.
    var showRaw: ShowRawToggle? {
        get { self[ShowRawKey.self] }
        set { self[ShowRawKey.self] = newValue }
    }

    private struct ShowRawKey: FocusedValueKey {
        typealias Value = ShowRawToggle
    }
}
