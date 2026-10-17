// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "NFOHero",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "NFOHero", targets: ["NFOHero"])
    ],
    targets: [
        .target(name: "NFOKit", swiftSettings: strict),
        .target(name: "NFOUI", dependencies: ["NFOKit"], swiftSettings: strict),
        .executableTarget(name: "NFOHero", dependencies: ["NFOUI"], swiftSettings: strict),
        .testTarget(
            name: "NFOKitTests",
            dependencies: ["NFOKit"],
            resources: [.copy("Fixtures")],
            swiftSettings: strict
        ),
    ]
)
