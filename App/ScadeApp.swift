import ScadeKit
import ScadeUI
import SwiftUI

@main
struct ScadeApp: App {
    /// Opened once at launch and handed to the view layer.
    ///
    /// Everything below this point receives the repositories explicitly —
    /// there is no shared singleton for a view to reach for.
    private let repositories: Repositories

    init() {
        do {
            repositories = Repositories(database: try AppDatabase.open(at: Self.databaseURL))
        } catch {
            // The app is a database with a UI on top; there is nothing
            // meaningful to show if it can't be opened.
            fatalError("Could not open the Scade database: \(error)")
        }
    }

    /// `scade.sqlite` in Application Support, created on first launch.
    private static var databaseURL: URL {
        let directory = URL.applicationSupportDirectory.appending(path: "Scade", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "scade.sqlite", directoryHint: .notDirectory)
    }

    var body: some Scene {
        WindowGroup {
            RootView(repositories: repositories)
        }
    }
}
