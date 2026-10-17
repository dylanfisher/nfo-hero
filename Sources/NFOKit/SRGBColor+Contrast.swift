import Foundation

extension SRGBColor {
    /// The contrast ratio a BBCode color must reach against the background. WCAG 2 asks 3:1 for
    /// large text, and 4.5:1 for body text. 3:1 keeps the colors trackers commonly use, such as
    /// `#3774F6` on white and on Dark Mode's background, exactly as written.
    public static let minimumTextContrast = 3.0

    /// WCAG 2 relative luminance, from 0 for black to 1 for white.
    public var relativeLuminance: Double {
        func linear(_ component: UInt8) -> Double {
            let value = Double(component) / 255
            return value <= 0.039_28 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2 contrast ratio, from 1 for equal luminance to 21 for black on white.
    public func contrastRatio(with other: SRGBColor) -> Double {
        let luminances = [relativeLuminance, other.relativeLuminance].sorted()
        return (luminances[1] + 0.05) / (luminances[0] + 0.05)
    }

    /// This color, or the least change toward black or white that reaches
    /// ``minimumTextContrast`` against `background`.
    ///
    /// NFO authors pick colors for one forum theme, so `[color=black]` vanishes in Dark Mode and
    /// `[color=yellow]` on white. Mixing toward black on a light background, and toward white on
    /// a dark one, keeps the hue while making the text readable.
    public func readable(on background: SRGBColor) -> SRGBColor {
        guard contrastRatio(with: background) < Self.minimumTextContrast else { return self }
        let target: SRGBColor = background.relativeLuminance > 0.18 ? .black : .white
        // Contrast grows with the mix amount, so a binary search finds the smallest that works.
        var low = 0.0
        var high = 1.0
        for _ in 0..<12 {
            let middle = (low + high) / 2
            if mixed(with: target, amount: middle).contrastRatio(with: background)
                >= Self.minimumTextContrast
            {
                high = middle
            } else {
                low = middle
            }
        }
        return mixed(with: target, amount: high)
    }

    private func mixed(with other: SRGBColor, amount: Double) -> SRGBColor {
        func mix(_ from: UInt8, _ to: UInt8) -> UInt8 {
            UInt8((Double(from) + (Double(to) - Double(from)) * amount).rounded())
        }
        return SRGBColor(
            red: mix(red, other.red), green: mix(green, other.green), blue: mix(blue, other.blue))
    }
}
