// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ScadeKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(name: "ScadeKit", targets: ["ScadeKit"]),
        .library(name: "ScadeUI", targets: ["ScadeUI"]),
    ],
    dependencies: [
        // Pinned to the same release the app target already resolves.
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1")
    ],
    targets: [
        // Models, persistence and business logic. Knows nothing about SwiftUI.
        .target(
            name: "ScadeKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        // Every screen in the app. The App target is a shell that presents
        // this, which keeps the views compilable — and therefore checkable —
        // without going through the Xcode project.
        .target(
            name: "ScadeUI",
            dependencies: ["ScadeKit"]
        ),
        .testTarget(
            name: "ScadeKitTests",
            dependencies: ["ScadeKit"]
        ),
    ]
)
