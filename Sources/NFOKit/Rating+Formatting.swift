import Foundation

extension Rating {
    /// The value out of its scale, such as `8.2/10` or `92/100`, rounded to one decimal place.
    /// A rating with no `max` is out of 10, as Kodi assumes.
    public var formattedValue: String {
        "\(Self.trimmed(value))/\(Self.trimmed(max ?? 10))"
    }

    /// One decimal place, dropping `.0`. `String(format:)` rather than a locale-aware formatter
    /// so the decimal separator matches the file.
    private static func trimmed(_ number: Double) -> String {
        let text = String(format: "%.1f", number)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
