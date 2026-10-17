import AppKit
import SwiftUI

/// Read-only, unwrapped monospaced text. NSTextView rather than SwiftUI Text, which lays out the
/// whole string up front and has no find bar.
struct NFOTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasHorizontalScroller = true
        let textView = scrollView.documentView as! NSTextView
        textView.isEditable = false
        textView.usesFindBar = true
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        // ASCII art breaks if lines wrap.
        textView.isHorizontallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = textView.maxSize
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
}
