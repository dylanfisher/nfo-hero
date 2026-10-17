import AppKit
import SwiftUI

/// Read-only, unwrapped monospaced text. NSTextView rather than SwiftUI Text, which lays out the
/// whole string up front and has no find bar.
struct NFOTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasHorizontalScroller = true
        // TextKit 1, because TextKit 2 lays out the whole document before the first draw when
        // lines do not wrap: 0.8 s on the main thread for a 5 MB file. TextKit 1 draws the first
        // screen and lays out the rest in the background, so for a large file the scrollers
        // settle over a few seconds. The other settings match the TextKit 2 view that
        // scrollableTextView() makes.
        let textView = NSTextView(usingTextLayoutManager: false)
        textView.autoresizingMask = [.width, .height]
        textView.isRichText = false
        textView.usesRuler = false
        scrollView.documentView = textView
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
