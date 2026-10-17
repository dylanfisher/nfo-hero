/// An sRGB color with 8-bit components, as BBCode writes it.
public struct SRGBColor: Sendable, Hashable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let white = SRGBColor(red: 255, green: 255, blue: 255)
    public static let black = SRGBColor(red: 0, green: 0, blue: 0)

    /// The CSS basic colors plus a few more that forum editors offer.
    private static let named: [String: SRGBColor] = [
        "black": .black, "white": .white,
        "silver": SRGBColor(red: 192, green: 192, blue: 192),
        "gray": SRGBColor(red: 128, green: 128, blue: 128),
        "grey": SRGBColor(red: 128, green: 128, blue: 128),
        "red": SRGBColor(red: 255, green: 0, blue: 0),
        "maroon": SRGBColor(red: 128, green: 0, blue: 0),
        "yellow": SRGBColor(red: 255, green: 255, blue: 0),
        "olive": SRGBColor(red: 128, green: 128, blue: 0),
        "lime": SRGBColor(red: 0, green: 255, blue: 0),
        "green": SRGBColor(red: 0, green: 128, blue: 0),
        "aqua": SRGBColor(red: 0, green: 255, blue: 255),
        "cyan": SRGBColor(red: 0, green: 255, blue: 255),
        "teal": SRGBColor(red: 0, green: 128, blue: 128),
        "blue": SRGBColor(red: 0, green: 0, blue: 255),
        "navy": SRGBColor(red: 0, green: 0, blue: 128),
        "fuchsia": SRGBColor(red: 255, green: 0, blue: 255),
        "magenta": SRGBColor(red: 255, green: 0, blue: 255),
        "purple": SRGBColor(red: 128, green: 0, blue: 128),
        "orange": SRGBColor(red: 255, green: 165, blue: 0),
        "pink": SRGBColor(red: 255, green: 192, blue: 203),
        "brown": SRGBColor(red: 165, green: 42, blue: 42),
        "gold": SRGBColor(red: 255, green: 215, blue: 0),
        "violet": SRGBColor(red: 238, green: 130, blue: 238),
        "indigo": SRGBColor(red: 75, green: 0, blue: 130),
    ]

    /// Parses `#RRGGBB`, `#RGB` or a color name, ignoring case. Nil for anything else.
    public init?(bbcodeValue value: String) {
        let value = value.lowercased()
        if let color = Self.named[value] {
            self = color
            return
        }
        guard value.hasPrefix("#") else { return nil }
        let digits = value.dropFirst().map { $0.hexDigitValue }
        guard digits.allSatisfy({ $0 != nil }) else { return nil }
        let nibbles = digits.map { UInt8($0!) }
        switch nibbles.count {
        case 6:
            self.init(
                red: nibbles[0] << 4 | nibbles[1], green: nibbles[2] << 4 | nibbles[3],
                blue: nibbles[4] << 4 | nibbles[5])
        case 3:
            self.init(
                red: nibbles[0] * 17, green: nibbles[1] * 17, blue: nibbles[2] * 17)
        default:
            return nil
        }
    }
}
