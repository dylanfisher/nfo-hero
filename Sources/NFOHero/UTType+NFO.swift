import Foundation
import UniformTypeIdentifiers

extension UTType {
    /// The NFO type. Resources/Info.plist declares it, so the identifier is read from there.
    static let nfo: UTType = {
        guard
            let declarations = Bundle.main.object(
                forInfoDictionaryKey: "UTImportedTypeDeclarations"
            ) as? [[String: Any]],
            let identifier = declarations.first?["UTTypeIdentifier"] as? String
        else {
            fatalError(
                "Info.plist declares no NFO type. Launch the bundled app with ./scripts/dev.")
        }
        return UTType(importedAs: identifier)
    }()
}
