import Foundation

/// The metadata record that DOS art editors append to a file: a 128-byte block starting `SAUCE00`,
/// optionally preceded by a comment block starting `COMNT`, with an end-of-file byte (0x1A) before
/// both. DOS stops reading text at the end-of-file byte, so none of it is part of the art.
public enum SAUCE {
    private static let recordSize = 128
    private static let recordID = Data("SAUCE".utf8)
    private static let commentID = Data("COMNT".utf8)
    /// The record's comment line count, at this offset within the record.
    private static let commentCountOffset = 104
    private static let commentLineSize = 64
    private static let endOfFile: UInt8 = 0x1A

    /// `data` without a SAUCE record, its comment block and the end-of-file bytes at the end.
    public static func removingTrailer(from data: Data) -> Data {
        var end = data.endIndex
        let record = data.suffix(recordSize)
        if record.count == recordSize, record.starts(with: recordID) {
            end -= recordSize
            let commentSize =
                commentID.count
                + Int(record[record.startIndex + commentCountOffset]) * commentLineSize
            let comment = data[data.startIndex..<end].suffix(commentSize)
            if commentSize > commentID.count, comment.count == commentSize,
                comment.starts(with: commentID)
            {
                end -= commentSize
            }
        }
        while end > data.startIndex, data[end - 1] == endOfFile {
            end -= 1
        }
        return data[data.startIndex..<end]
    }
}
