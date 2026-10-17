import SwiftUI

/// The key window's View → Show Raw state, published as a focused value.
///
/// Compares by the value rather than the binding because SwiftUI rebuilds the menu only when the
/// focused value changes, and a `@SceneStorage` binding is equal to itself before and after a
/// toggle. With a bare binding the checkmark keeps the old state, and the next toggle from the
/// menu writes that old value again.
struct ShowRawToggle: Equatable {
    let isOn: Binding<Bool>
    private let value: Bool

    init(_ isOn: Binding<Bool>) {
        self.isOn = isOn
        value = isOn.wrappedValue
    }

    static func == (lhs: ShowRawToggle, rhs: ShowRawToggle) -> Bool {
        lhs.value == rhs.value
    }
}
