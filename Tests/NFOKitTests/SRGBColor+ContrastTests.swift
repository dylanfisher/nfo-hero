import NFOKit
import Testing

private let darkBackground = SRGBColor(red: 0x1E, green: 0x1E, blue: 0x1E)

@Test func measuresContrastLikeWCAG() {
    #expect(abs(SRGBColor.black.contrastRatio(with: .white) - 21) < 0.01)
    #expect(SRGBColor.white.contrastRatio(with: .white) == 1)
}

@Test func keepsColorsThatAreAlreadyReadable() {
    let blue = SRGBColor(red: 0x37, green: 0x74, blue: 0xF6)
    #expect(blue.readable(on: .white) == blue)
    #expect(blue.readable(on: darkBackground) == blue)
}

@Test func lightensDarkColorsInDarkMode() {
    let readable = SRGBColor.black.readable(on: darkBackground)
    #expect(readable.contrastRatio(with: darkBackground) >= SRGBColor.minimumTextContrast)
    // The least change: a gray, not white.
    #expect(readable != .white)
    #expect(readable.red == readable.green && readable.green == readable.blue)
}

@Test func darkensLightColorsOnWhiteKeepingTheHue() {
    let yellow = SRGBColor(red: 255, green: 255, blue: 0)
    let readable = yellow.readable(on: .white)
    #expect(readable.contrastRatio(with: .white) >= SRGBColor.minimumTextContrast)
    #expect(readable.red == readable.green && readable.blue == 0 && readable.red > 0)
}
