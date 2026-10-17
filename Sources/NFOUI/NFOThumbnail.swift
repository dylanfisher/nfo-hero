import AppKit
import NFOKit

/// The Finder thumbnail of an NFO: the top of the text a text view shows for it, in the same font,
/// line height and BBCode styles, drawn dark on a light page.
public struct NFOThumbnail: Sendable {
    private let text: String
    private let runs: [BBCodeText.Run]
    /// The columns the page is wide. Text past them is cut off.
    private let columns: Int
    /// The lines the page is tall.
    private let lines: Int

    /// Pages are at least this many columns wide, so a short `.diz` is not drawn huge, and at most
    /// this many, so a few long lines do not shrink the art to nothing.
    private static let columnRange = 40...100
    /// The page is at most this many times as tall as it is wide, about a sheet of paper.
    private static let maxAspectRatio: CGFloat = 1.3
    /// Blank columns around the text, and as many points above and below it.
    private static let marginColumns: CGFloat = 2

    public init(nfo: NFO) {
        let fullText: String
        switch nfo.kind {
        case .scene(let bbcode?):
            fullText = bbcode.text
            runs = bbcode.runs
        default:
            fullText = nfo.text
            runs = []
        }
        columns = min(
            max(nfo.textExtent.longestLine, Self.columnRange.lowerBound),
            Self.columnRange.upperBound)
        let width = Self.pageWidth(columns: columns)
        let maxLines = Int(
            ((width * Self.maxAspectRatio - 2 * Self.margin) / NFOTextStyle.lineHeight).rounded(
                .down))
        lines = min(nfo.textExtent.lineCount, maxLines)
        // Only the lines on the page, so a 16 MB file is not styled to draw its first screen.
        var end = fullText.startIndex
        var lineBreaks = 0
        while end < fullText.endIndex, lineBreaks < lines {
            if fullText[end].isNewline { lineBreaks += 1 }
            end = fullText.index(after: end)
        }
        text = String(fullText[..<end])
    }

    private static var margin: CGFloat { marginColumns * NFOTextStyle.advance }

    private static func pageWidth(columns: Int) -> CGFloat {
        CGFloat(columns) * NFOTextStyle.advance + 2 * margin
    }

    private var pageSize: CGSize {
        CGSize(
            width: Self.pageWidth(columns: columns),
            height: CGFloat(lines) * NFOTextStyle.lineHeight + 2 * Self.margin)
    }

    /// The page's size scaled to fit `maximum`, filling its width or its height.
    public func size(fitting maximum: CGSize) -> CGSize {
        let page = pageSize
        let scale = min(maximum.width / page.width, maximum.height / page.height)
        return CGSize(width: page.width * scale, height: page.height * scale)
    }

    /// Draws the page into the current graphics context, which has AppKit's coordinates, scaled to
    /// fill `size`. False when there is no current context to draw into.
    public func draw(in size: CGSize) -> Bool {
        guard let context = NSGraphicsContext.current?.cgContext else { return false }
        let page = pageSize
        let scale = size.width / page.width
        context.saveGState()
        defer { context.restoreGState() }
        context.scaleBy(x: scale, y: scale)
        // Light, so the text's dynamic colors resolve dark and BBCode colors stay readable on it.
        guard let light = NSAppearance(named: .aqua) else {
            fatalError("The system has no aqua appearance")
        }
        light.performAsCurrentDrawingAppearance {
            NSColor.textBackgroundColor.setFill()
            CGRect(origin: .zero, size: page).fill()
            let textRect = CGRect(origin: .zero, size: page).insetBy(
                dx: Self.margin, dy: Self.margin)
            NSBezierPath(rect: textRect).addClip()
            let length = (text as NSString).length
            let visibleRuns = runs.compactMap { run -> BBCodeText.Run? in
                let range = NSIntersectionRange(run.range, NSRange(location: 0, length: length))
                return range.length > 0 ? BBCodeText.Run(range: range, style: run.style) : nil
            }
            // As wide as it needs, so lines are cut at the margin instead of wrapping.
            let unwrapped = CGRect(
                x: textRect.minX, y: textRect.minY, width: .greatestFiniteMagnitude,
                height: textRect.height)
            NFOTextStyle.styledText(text, runs: visibleRuns).draw(
                with: unwrapped, options: [.usesLineFragmentOrigin])
        }
        return true
    }
}
