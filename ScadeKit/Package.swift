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
        //
        // Main-actor by default, matching the App target's
        // SWIFT_DEFAULT_ACTOR_ISOLATION. Views and their models are main-actor
        // work by definition, so the annotation was on every one of them;
        // stating it once means new code inherits it instead of remembering
        // it. `ScadeKit` deliberately does *not* do this — the domain layer is
        // non-isolated and `Sendable` so it can be used from anywhere.
        .target(
            name: "ScadeUI",
            dependencies: ["ScadeKit"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "ScadeKitTests",
            dependencies: ["ScadeKit"]
        ),
    ]
)
