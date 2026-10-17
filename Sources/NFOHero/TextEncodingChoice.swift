import NFOKit
import SwiftUI

/// The key window's View → Text Encoding state, published as a focused value. Compares by the
/// value rather than the binding, for the reason given on `ShowRawToggle`.
struct TextEncodingChoice: Equatable {
    /// Nil for the detected encoding.
    let selection: Binding<TextEncoding?>
    /// The encoding the file was opened with.
    let detected: TextEncoding
    private let value: TextEncoding?

    init(_ selection: Binding<TextEncoding?>, detected: TextEncoding) {
        self.selection = selection
        self.detected = detected
        value = selection.wrappedValue
    }

    static func == (lhs: TextEncodingChoice, rhs: TextEncodingChoice) -> Bool {
        lhs.value == rhs.value && lhs.detected == rhs.detected
    }
}
