import NFOKit
import SwiftUI
import UniformTypeIdentifiers

struct NFODocument: FileDocument {
    static var readableContentTypes: [UTType] { [.nfo] }

    let nfo: NFO

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        nfo = try NFO.parse(data)
    }

    // Opened with DocumentGroup(viewing:), so SwiftUI never asks to save.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}
