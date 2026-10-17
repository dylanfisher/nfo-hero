import NFOKit
import Testing

@Test func parsesHexColors() {
    #expect(SRGBColor(bbcodeValue: "#3774F6") == SRGBColor(red: 0x37, green: 0x74, blue: 0xF6))
    #expect(SRGBColor(bbcodeValue: "#3774f6") == SRGBColor(red: 0x37, green: 0x74, blue: 0xF6))
    #expect(SRGBColor(bbcodeValue: "#F80") == SRGBColor(red: 0xFF, green: 0x88, blue: 0x00))
}

@Test func parsesColorNames() {
    #expect(SRGBColor(bbcodeValue: "Red") == SRGBColor(red: 255, green: 0, blue: 0))
    #expect(SRGBColor(bbcodeValue: "grey") == SRGBColor(bbcodeValue: "gray"))
    #expect(SRGBColor(bbcodeValue: "orange") == SRGBColor(red: 255, green: 165, blue: 0))
}

@Test func rejectsOtherColorValues() {
    for value in ["", "#", "#12", "#1234", "#GGGGGG", "3774F6", "notacolor", "#+12345"] {
        #expect(SRGBColor(bbcodeValue: value) == nil, "\(value)")
    }
}
