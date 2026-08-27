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
            repositories = Repositories(database: try Self.makeDatabase())
        } catch {
            // The app is a database with a UI on top; there is nothing
            // meaningful to show if it can't be opened.
            fatalError("Could not open the Scade database: \(error)")
        }
    }

    /// The real database, unless UI tests asked for a throwaway one.
    ///
    /// Automation creates and deletes records, so it must never be pointed at
    /// Application Support. An in-memory database also starts every test from
    /// a known-empty state without needing a teardown step that could fail.
    private static func makeDatabase() throws -> AppDatabase {
        guard ProcessInfo.processInfo.arguments.contains(Self.uiTestingArgument) else {
            return try AppDatabase.open(at: databaseURL)
        }
        return try AppDatabase.inMemory()
    }

    /// Passed by `ScadeUITests`; see the matching constant there.
    private static let uiTestingArgument = "-ui-testing"

    /// `scade.sqlite` in Application Support, created on first launch.
    private static var databaseURL: URL {
        let directory = URL.applicationSupportDirectory.appending(path: "Scade", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "scade.sqlite", directoryHint: .notDirectory)
    }

    var body: some Scene {
        WindowGroup(id: ScadeWindow.main) {
            RootView(repositories: repositories)
        }
        // The whole menu bar (SPEC-POLISH §1), declared in ScadeUI so this
        // target stays a shell that opens a database.
        .commands { ScadeCommands() }

        // macOS only, and the reason Settings has no sidebar row: this is
        // what puts "Scade ▸ Settings…" in the app menu and answers ⌘,.
        #if os(macOS)
        Settings {
            SettingsWindow(repositories: repositories)
        }
        #endif
    }
}
