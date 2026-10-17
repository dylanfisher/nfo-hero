import Foundation

/// An encoding a scene NFO is decoded with: detected when the file is parsed, or chosen with
/// View → Text Encoding.
public enum TextEncoding: String, Sendable, CaseIterable {
    case utf8
    case cp437
    /// Windows' Western encoding, which text NFOs written outside DOS use for accented letters.
    case windows1252

    /// Decodes all of `data`. Bytes that are not valid UTF-8 become U+FFFD. The five bytes that
    /// Windows-1252 leaves undefined become the C1 controls with the same number, as Windows
    /// decodes them.
    func decode(_ data: Data) -> String {
        switch self {
        case .utf8:
            String(decoding: data, as: UTF8.self)
        case .cp437:
            CP437.decode(data)
        case .windows1252:
            Self.windows1252Table.decode(data)
        }
    }

    private static let windows1252Table = SingleByteEncoding(
        scalars: (0...255).map { byte in
            String(data: Data([UInt8(byte)]), encoding: .windowsCP1252)?.unicodeScalars.first
                ?? Unicode.Scalar(UInt8(byte))
        })
}
