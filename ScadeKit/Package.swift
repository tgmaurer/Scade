// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ScadeKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(name: "ScadeKit", targets: ["ScadeKit"])
    ],
    dependencies: [
        // Pinned to the same release the app target already resolves.
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1")
    ],
    targets: [
        .target(
            name: "ScadeKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ScadeKitTests",
            dependencies: ["ScadeKit"],
            path: "Tests/ScadeKitTests"
        ),
    ]
)
