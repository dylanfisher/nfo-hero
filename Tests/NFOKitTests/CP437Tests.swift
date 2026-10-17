import Foundation
import NFOKit
import Testing

@Test func decodesBlockElements() throws {
    #expect(try CP437.decode(Data([0xDB, 0xB2, 0xB1, 0xB0])) == "█▓▒░")
}
