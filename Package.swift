// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SnapLine",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SnapLineCore",
            targets: ["SnapLineCore"]
        ),
        .executable(
            name: "SnapLine",
            targets: ["SnapLine"]
        )
    ],
    targets: [
        .target(
            name: "SnapLineCore",
            path: "Sources/SnapLineCore",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("QuickLookUI"),
                .linkedFramework("CoreServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        ),
        .executableTarget(
            name: "SnapLine",
            dependencies: ["SnapLineCore"],
            path: "Sources/SnapLine",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "SnapLineTestSuite",
            dependencies: ["SnapLineCore"],
            path: "Tests/SnapLineTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
