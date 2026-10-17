import AppKit
import NFOKit

/// How NFO text is drawn: the font, the line height and the BBCode styles.
enum NFOTextStyle {
    // The fonts and paragraph style are `nonisolated(unsafe)` because AppKit does not mark them
    // Sendable, although they are immutable and documented as safe to share between threads.

    /// Menlo rather than the system monospaced font, which has no glyph for 25 of CP437's
    /// characters, such as `☺`, `♥`, `⌐` and `≡`. Those came from Menlo anyway, at Menlo's
    /// narrower advance, and moved the rest of their line left.
    nonisolated(unsafe) private static let font: NSFont = {
        guard let font = NSFont(name: "Menlo-Regular", size: 13) else {
            fatalError("Menlo, which ships with macOS, is not installed")
        }
        return font
    }()
    nonisolated(unsafe) private static let boldFont: NSFont = {
        guard let font = NSFont(name: "Menlo-Bold", size: font.pointSize) else {
            fatalError("Menlo Bold, which ships with macOS, is not installed")
        }
        return font
    }()
    /// The width of one column. Bold BBCode is drawn in Menlo Bold, which has the same advance.
    static let advance = font.advancement(forGlyph: font.glyph(withName: "M")).width
    /// The height of the full block, `█`, so rows of blocks touch the way they do in DOS. The
    /// font's own line height is 15 pt, which left a 2 pt stripe between rows of block art.
    /// TextKit takes the difference from above the ascender, and letters still fit.
    static let lineHeight: CGFloat = {
        var character = UniChar(0x2588)
        var glyph = CGGlyph()
        guard CTFontGetGlyphsForCharacters(font, &character, &glyph, 1) else {
            fatalError("Menlo has no full block glyph")
        }
        return CTFontGetBoundingRectsForGlyphs(font, .horizontal, &glyph, nil, 1).height
    }()
    nonisolated(unsafe) private static let paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }()

    /// `text` in the font and line height, with `runs` drawn in their styles. The colors are
    /// dynamic, and resolve against the appearance the text is drawn in.
    static func styledText(_ text: String, runs: [BBCodeText.Run]) -> NSAttributedString {
        let plain: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: NSColor.textColor,
            .paragraphStyle: paragraphStyle,
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
                    let attributes = attributes(for: run.style, plain: plain)
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
            attributes[.font] = self.font(
                bold: style.isBold ? boldFont : font, italic: style.isItalic)
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
