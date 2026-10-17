// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "NFOHero",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "NFOHero", targets: ["NFOHero"]),
        .executable(name: "NFOQuickLook", targets: ["NFOQuickLook"]),
        .executable(name: "NFOThumbnail", targets: ["NFOThumbnail"]),
    ],
    targets: [
        .target(name: "NFOKit", swiftSettings: strict),
        .target(name: "NFOUI", dependencies: ["NFOKit"], swiftSettings: strict),
        .executableTarget(name: "NFOHero", dependencies: ["NFOUI"], swiftSettings: strict),
        // The Quick Look preview extension. An app extension starts in Foundation's
        // NSExtensionMain, which loads the principal class named in its Info.plist, so the
        // target has no main of its own. Without -parse-as-library SwiftPM compiles a
        // one-file executable as top-level code, whose globals are set up in a main that
        // never runs here, and they read as zero.
        .executableTarget(
            name: "NFOQuickLook",
            dependencies: ["NFOUI"],
            swiftSettings: strict + [.unsafeFlags(["-parse-as-library"])],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])]
        ),
        // The Quick Look thumbnail extension, built the same way.
        .executableTarget(
            name: "NFOThumbnail",
            dependencies: ["NFOUI"],
            swiftSettings: strict + [.unsafeFlags(["-parse-as-library"])],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])]
        ),
        .testTarget(
            name: "NFOKitTests",
            dependencies: ["NFOKit"],
            resources: [.copy("Fixtures")],
            swiftSettings: strict
        ),
    ]
)
