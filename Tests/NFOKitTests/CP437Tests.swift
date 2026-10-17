import Foundation
import NFOKit
import Testing

@Test func decodesBlockElements() {
    #expect(CP437.decode(Data([0xDB, 0xB2, 0xB1, 0xB0])) == "█▓▒░")
}

@Test func decodesControlBytesAsTheirGlyphs() {
    #expect(CP437.decode(Data([0x01, 0x03, 0x10, 0x11, 0x1A, 0x1F, 0x7F])) == "☺♥►◄→▼⌂")
}

@Test func keepsTabsAndLineBreaksAsControls() {
    #expect(CP437.decode(Data([0x41, 0x09, 0x42, 0x0D, 0x0A, 0x43])) == "A\tB\r\nC")
}

@Test func drawsNullAsASpace() {
    #expect(CP437.decode(Data([0x41, 0x00, 0x42])) == "A B")
}

@Test func decodesTheGlyphsMissingFromTheSystemMonospacedFont() {
    #expect(CP437.decode(Data([0xA9, 0xEF, 0xF0, 0xF4, 0xF5])) == "⌐∩≡⌠⌡")
}
