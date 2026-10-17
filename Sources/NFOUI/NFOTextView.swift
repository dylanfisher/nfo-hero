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

    private static let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    /// The width of one column. Bold BBCode is drawn in the bold monospaced font, which has the
    /// same advance, and TextKit draws CP437's box and block characters at it too.
    private static let advance = font.advancement(forGlyph: font.glyph(withName: "M")).width
    private static let lineHeight = NSLayoutManager().defaultLineHeight(for: font)
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
        textView.font = Self.font
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
        let width = CGFloat(extent.longestLine) * Self.advance + 2 * Self.lineFragmentPadding
        let height = CGFloat(extent.lineCount) * Self.lineHeight
        return CGSize(
            width: proposal.width ?? width + scrollers,
            height: proposal.height ?? height + scrollers)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        guard textView.string != text || context.coordinator.runs != runs else { return }
        if runs.isEmpty && context.coordinator.runs.isEmpty {
            textView.string = text
        } else {
            // Through the text storage, because setting `string` gives all of the text the
            // attributes of the first character it replaces.
            textView.textStorage?.setAttributedString(styledText())
        }
        context.coordinator.runs = runs
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// The runs the text view shows, to tell when they change.
    final class Coordinator {
        var runs: [BBCodeText.Run] = []
    }

    private func styledText() -> NSAttributedString {
        let plain: [NSAttributedString.Key: Any] = [
            .font: Self.font, .foregroundColor: NSColor.textColor,
        ]
        let styled = NSMutableAttributedString(string: text, attributes: plain)
        // A file has a handful of styles and can have a million runs, so each style's
        // attributes are built once.
        var attributesByStyle: [BBCodeText.Style: [NSAttributedString.Key: Any]] = [:]
        styled.beginEditing()
        for run in runs {
            let attributes =
                attributesByStyle[run.style]
                ?? {
                    let attributes = Self.attributes(for: run.style, plain: plain)
                    attributesByStyle[run.style] = attributes
                    return attributes
                }()
            styled.setAttributes(attributes, range: run.range)
        }
        styled.endEditing()
        return styled
    }

    private static func attributes(
        for style: BBCodeText.Style, plain: [NSAttributedString.Key: Any]
    ) -> [NSAttributedString.Key: Any] {
        var attributes = plain
        if style.isBold || style.isItalic {
            let base =
                style.isBold
                ? NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .bold) : font
            attributes[.font] = self.font(bold: base, italic: style.isItalic)
        }
        if style.isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if let color = style.color {
            attributes[.foregroundColor] = readableColor(color)
        }
        return attributes
    }

    private static func font(bold font: NSFont, italic: Bool) -> NSFont {
        guard italic else { return font }
        let descriptor = font.fontDescriptor.withSymbolicTraits(
            font.fontDescriptor.symbolicTraits.union(.italic))
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }

    /// `color`, adjusted to stay readable on the text background of the current appearance.
    /// See ``SRGBColor/readable(on:)``.
    private static func readableColor(_ color: SRGBColor) -> NSColor {
        NSColor(name: nil) { appearance in
            var background = SRGBColor.white
            appearance.performAsCurrentDrawingAppearance {
                if let resolved = NSColor.textBackgroundColor.usingColorSpace(.sRGB) {
                    background = SRGBColor(
                        red: UInt8((resolved.redComponent * 255).rounded()),
                        green: UInt8((resolved.greenComponent * 255).rounded()),
                        blue: UInt8((resolved.blueComponent * 255).rounded()))
                }
            }
            let readable = color.readable(on: background)
            return NSColor(
                srgbRed: CGFloat(readable.red) / 255, green: CGFloat(readable.green) / 255,
                blue: CGFloat(readable.blue) / 255, alpha: 1)
        }
    }
}
