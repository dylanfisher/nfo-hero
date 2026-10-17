// Draws the NFO document icon: a white page with a folded corner, "NFO" in
// block letters and a ░▒▓█ shading strip, as scene NFOs draw their logos. Writes the
// iconset folder iconutil turns into an .icns.
//
// Usage: swift scripts/document-icon.swift <out.iconset>
import AppKit

let canvas: CGFloat = 1024
// The page within the canvas, as macOS document icons place it.
let page = CGRect(x: 160, y: 72, width: 704, height: 880)
let fold: CGFloat = 176
let corner: CGFloat = 40

let paper = NSColor(srgbRed: 0.99, green: 0.99, blue: 1.00, alpha: 1)
let foldColor = NSColor(srgbRed: 0.86, green: 0.88, blue: 0.92, alpha: 1)
// Teal rather than cyan at the top, which washes out on white.
let top = NSColor(srgbRed: 0.08, green: 0.66, blue: 0.75, alpha: 1)
let bottom = NSColor(srgbRed: 0.18, green: 0.38, blue: 0.92, alpha: 1)
let shadow = NSColor(srgbRed: 0.80, green: 0.85, blue: 0.95, alpha: 1)

// 5 × 5 block letters, top row first.
let letters = [
    ["#...#", "##..#", "#.#.#", "#..##", "#...#"],
    ["#####", "#....", "####.", "#....", "#...."],
    [".###.", "#...#", "#...#", "#...#", ".###."],
]

func pagePath() -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: page.minX + corner, y: page.minY))
    path.line(to: CGPoint(x: page.maxX - corner, y: page.minY))
    path.curve(
        to: CGPoint(x: page.maxX, y: page.minY + corner),
        controlPoint1: CGPoint(x: page.maxX, y: page.minY),
        controlPoint2: CGPoint(x: page.maxX, y: page.minY))
    path.line(to: CGPoint(x: page.maxX, y: page.maxY - fold))
    path.line(to: CGPoint(x: page.maxX - fold, y: page.maxY))
    path.line(to: CGPoint(x: page.minX + corner, y: page.maxY))
    path.curve(
        to: CGPoint(x: page.minX, y: page.maxY - corner),
        controlPoint1: CGPoint(x: page.minX, y: page.maxY),
        controlPoint2: CGPoint(x: page.minX, y: page.maxY))
    path.line(to: CGPoint(x: page.minX, y: page.minY + corner))
    path.curve(
        to: CGPoint(x: page.minX + corner, y: page.minY),
        controlPoint1: CGPoint(x: page.minX, y: page.minY),
        controlPoint2: CGPoint(x: page.minX, y: page.minY))
    path.close()
    return path
}

func drawIcon() {
    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -12), blur: 28,
        color: NSColor.black.withAlphaComponent(0.35).cgColor)
    paper.setFill()
    pagePath().fill()
    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    let foldPath = NSBezierPath()
    foldPath.move(to: CGPoint(x: page.maxX - fold, y: page.maxY))
    foldPath.line(to: CGPoint(x: page.maxX - fold, y: page.maxY - fold + corner))
    foldPath.curve(
        to: CGPoint(x: page.maxX - fold + corner, y: page.maxY - fold),
        controlPoint1: CGPoint(x: page.maxX - fold, y: page.maxY - fold),
        controlPoint2: CGPoint(x: page.maxX - fold, y: page.maxY - fold))
    foldPath.line(to: CGPoint(x: page.maxX, y: page.maxY - fold))
    foldPath.close()
    foldColor.setFill()
    foldPath.fill()

    // 17 columns: three 5-column letters with a column between them.
    let cell: CGFloat = 32
    let gap: CGFloat = 2
    let lettersWidth = 17 * cell
    let originX = page.midX - lettersWidth / 2
    let originY: CGFloat = 520
    let gradient = NSGradient(starting: top, ending: bottom)!

    for pass in 0..<2 {
        for (index, rows) in letters.enumerated() {
            for (row, line) in rows.enumerated() {
                for (column, mark) in line.enumerated() where mark == "#" {
                    let x = originX + CGFloat(index * 6 + column) * cell
                    let y = originY + CGFloat(4 - row) * cell
                    var block = CGRect(x: x, y: y, width: cell - gap, height: cell - gap)
                    if pass == 0 {
                        // A drop shadow, down and right, as scene logos have.
                        block = block.offsetBy(dx: cell / 3, dy: -cell / 3)
                        shadow.setFill()
                        block.fill()
                    } else {
                        // Each row a step of the gradient, top to bottom.
                        gradient.interpolatedColor(atLocation: CGFloat(row) / 4).setFill()
                        block.fill()
                    }
                }
            }
        }
    }

    // ░▒▓█ shading strip under the letters.
    let strip: [CGFloat] = [0.18, 0.18, 0.4, 0.4, 0.7, 0.7, 1, 1, 1, 0.7, 0.7, 0.4, 0.4, 0.18, 0.18, 0.18, 0.18]
    for (column, alpha) in strip.enumerated() {
        bottom.withAlphaComponent(alpha).setFill()
        CGRect(x: originX + CGFloat(column) * cell, y: 400, width: cell - gap, height: cell - gap)
            .fill()
    }

    // Lines of text below, short and long, as the body of a release NFO.
    let lineColor = NSColor(srgbRed: 0.72, green: 0.75, blue: 0.80, alpha: 1)
    lineColor.setFill()
    let widths: [CGFloat] = [0.78, 0.62, 0.84, 0.5]
    for (index, width) in widths.enumerated() {
        CGRect(
            x: originX, y: 300 - CGFloat(index) * 52, width: lettersWidth * width, height: 20
        ).fill()
    }
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        guard
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
            let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            fatalError("Cannot make a \(pixels) px bitmap")
        }
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)
        drawIcon()
        context.flushGraphics()
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Cannot encode \(name)")
        }
        try png.write(to: output.appendingPathComponent(name))
    }
}
