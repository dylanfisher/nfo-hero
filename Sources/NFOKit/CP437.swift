import Foundation

/// IBM code page 437, the DOS encoding NFO art is drawn in.
public enum CP437 {
    public struct DecodingError: Error {}

    private static let encoding = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue)
        )
    )

    /// Decodes `data` as CP437. Bytes 0x80–0xFF map to their box-drawing and block glyphs.
    public static func decode(_ data: Data) throws -> String {
        guard let text = String(data: data, encoding: encoding) else {
            throw DecodingError()
        }
        return text
    }
}
