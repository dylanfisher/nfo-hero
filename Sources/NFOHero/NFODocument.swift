import NFOKit
import SwiftUI
import UniformTypeIdentifiers

struct NFODocument: FileDocument {
    static var readableContentTypes: [UTType] { [.nfo] }

    /// The file's bytes, to decode again with the encoding chosen in View → Text Encoding.
    let data: Data
    let nfo: NFO

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        nfo = try NFO.parse(data)
    }

    // Opened with DocumentGroup(viewing:), so SwiftUI never asks to save.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}
