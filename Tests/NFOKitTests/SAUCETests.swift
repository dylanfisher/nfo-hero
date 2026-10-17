import Foundation
import NFOKit
import Testing

/// A SAUCE record with `comments` comment lines, padded to 128 bytes.
private func record(comments: UInt8 = 0) -> Data {
    var record = Data("SAUCE00".utf8) + Data("Title".utf8)
    record += Data(repeating: 0x20, count: 104 - record.count)
    record.append(comments)
    record += Data(repeating: 0, count: 128 - record.count)
    return record
}

private let art = Data("██▓▒░\r\n".utf8)

@Test func removesTheRecordAndTheEndOfFileByte() {
    #expect(SAUCE.removingTrailer(from: art + [0x1A] + record()) == art)
}

@Test func removesTheCommentBlock() {
    let comments = Data("COMNT".utf8) + Data(repeating: 0x41, count: 2 * 64)
    #expect(SAUCE.removingTrailer(from: art + [0x1A] + comments + record(comments: 2)) == art)
}

@Test func keepsTextBeforeACommentCountWithNoBlock() {
    let text = Data(repeating: 0x41, count: 200)
    #expect(SAUCE.removingTrailer(from: text + record(comments: 1)) == text)
}

@Test func removesEndOfFileBytesWithoutARecord() {
    #expect(SAUCE.removingTrailer(from: art + [0x1A, 0x1A]) == art)
}

@Test func leavesTextWithoutATrailerAlone() {
    let text = Data("SAUCE00 is mentioned here, not at the end".utf8)
    #expect(SAUCE.removingTrailer(from: text) == text)
}

@Test func keepsAnEndOfFileByteInsideTheText() {
    let text = Data([0x41, 0x1A, 0x42])
    #expect(SAUCE.removingTrailer(from: text) == text)
}
