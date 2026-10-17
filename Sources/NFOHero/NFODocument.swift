import NFOKit
import SwiftUI
import UniformTypeIdentifiers

struct NFODocument: FileDocument {
    static var readableContentTypes: [UTType] { [.nfo] }

    let text: String

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = try CP437.decode(data)
    }

    // Opened with DocumentGroup(viewing:), so SwiftUI never asks to save.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}
