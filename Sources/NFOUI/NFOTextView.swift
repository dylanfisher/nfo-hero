import AppKit
import NFOKit
import SwiftUI

/// Read-only, unwrapped monospaced text. NSTextView rather than SwiftUI Text, which lays out the
/// whole string up front and has no find bar.
struct NFOTextView: NSViewRepresentable {
    let text: String
    /// Styles from BBCode. Empty for plain text.
    var runs: [BBCodeText.Run] = []
    /// The extent of `text`, measured when the file was parsed. With it, the view's ideal size
    /// fits the whole text without scrolling, which sizes the window it opens in.
    var extent: TextExtent?

    private static let lineFragmentPadding = NSTextContainer().lineFragmentPadding

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
        // ASCII art breaks if lines wrap.
        textView.isHorizontallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = textView.maxSize
        return scrollView
    }

    /// With an extent, the size that shows the whole text for any dimension that is not proposed.
    /// Measured from the extent rather than by laying out the text, which for a large file takes
    /// seconds.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context)
        -> CGSize?
    {
        guard let extent else { return nil }
        // Legacy scrollers, shown with a mouse or by the "Show scroll bars: Always" setting, take
        // space from the text. Overlay scrollers draw over it.
        let scrollers =
            NSScroller.preferredScrollerStyle == .legacy
            ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy) : 0
        // The text container pads each line on both sides.
        let width =
            CGFloat(extent.longestLine) * NFOTextStyle.advance + 2 * Self.lineFragmentPadding
        let height = CGFloat(extent.lineCount) * NFOTextStyle.lineHeight
        return CGSize(
            width: proposal.width ?? width + scrollers,
            height: proposal.height ?? height + scrollers)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        guard textView.string != text || context.coordinator.runs != runs else { return }
        // Through the text storage, because setting `string` gives all of the text the
        // attributes of the first character it replaces, and plain text needs the line height.
        textView.textStorage?.setAttributedString(NFOTextStyle.styledText(text, runs: runs))
        context.coordinator.runs = runs
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// The runs the text view shows, to tell when they change.
    final class Coordinator {
        var runs: [BBCodeText.Run] = []
    }
}
