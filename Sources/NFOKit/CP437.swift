import Foundation

/// IBM code page 437, the DOS encoding NFO art is drawn in.
public enum CP437 {
    /// Decodes every byte to the glyph DOS draws for it: 0x80–0xFF to box-drawing, block and
    /// accented characters, and 0x01–0x1F and 0x7F to `☺` … `▼` and `⌂`. Tab, line feed and
    /// carriage return stay controls, because NFOs use them as such. 0x00 is drawn blank, so it
    /// becomes a space.
    public static func decode(_ data: Data) -> String {
        encoding.decode(data)
    }

    /// DOS's glyphs for 0x00–0x1F, which `String.Encoding` decodes as ASCII controls.
    private static let controlGlyphs = Array(" ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼".unicodeScalars)

    private static let encoding: SingleByteEncoding = {
        let system = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue)
            )
        )
        let bytes = Data((0...255).map { UInt8($0) })
        guard let decoded = String(data: bytes, encoding: system),
            decoded.unicodeScalars.count == 256
        else {
            fatalError("The system cannot decode all 256 bytes of CP437")
        }
        var scalars = Array(decoded.unicodeScalars)
        for (byte, glyph) in controlGlyphs.enumerated() where ![0x09, 0x0A, 0x0D].contains(byte) {
            scalars[byte] = glyph
        }
        scalars[0x7F] = "⌂"
        return SingleByteEncoding(scalars: scalars)
    }()
}
