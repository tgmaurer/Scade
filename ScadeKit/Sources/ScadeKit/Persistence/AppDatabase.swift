import Foundation
import GRDB

/// Owns the SQLite connection and hands out explicit read/write access.
///
/// There is deliberately no `shared` singleton and no cache: an `AppDatabase`
/// is created once at launch and passed down. Every read is a query someone
/// asked for, at the moment they asked for it — nothing is retained between
/// calls and nothing goes stale behind the caller's back.
public struct AppDatabase: Sendable {
    public let writer: any DatabaseWriter

    /// Wraps an existing connection and brings its schema up to date.
    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try ScadeMigrator.migrator.migrate(writer)
    }

    /// A private in-memory database. Used by tests, which run against real
    /// SQLite rather than a stand-in.
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue(configuration: .scade))
    }

    /// Opens (or creates) the database file at `url`.
    public static func open(at url: URL) throws -> AppDatabase {
        try AppDatabase(DatabaseQueue(path: url.path(percentEncoded: false), configuration: .scade))
    }

    public func read<T>(_ value: (Database) throws -> T) throws -> T {
        try writer.read(value)
    }

    public func write<T>(_ updates: (Database) throws -> T) throws -> T {
        try writer.write(updates)
    }

    /// Runs `fetch` now, and again whenever anything it read is written to.
    ///
    /// This is the one exception to "nothing is retained between calls" above,
    /// and it exists because the alternative was worse: screens fetched when
    /// they appeared, and `onAppear` doesn't run again when a pushed screen is
    /// popped, so a list could sit showing a record that had been renamed on
    /// the screen it opened. Every fix for that shape of bug is a way of
    /// guessing when data *might* have changed. SQLite already knows.
    ///
    /// It is still an explicit query — `fetch` is written by the caller and
    /// re-run whole. Nothing is tracked per object, no graph is kept, and
    /// there is no cache to invalidate; each delivery is a fresh read.
    ///
    /// The stream is bridged from GRDB's `ValueObservation` so callers never
    /// name a GRDB type. Cancelling the task that consumes it — which SwiftUI
    /// does when a `task` modifier's view goes away — stops the observation.
    ///
    /// `fetch` may run several queries; they see one consistent snapshot,
    /// which separate reads do not.
    public func observe<Value: Sendable & Equatable>(
        _ fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AsyncThrowingStream<Value, any Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                let cancellable = ValueObservation
                    .tracking(fetch)
                    // A write to a tracked table re-runs the query even when the
                    // result is identical. Without this, editing one subject
                    // would republish every other screen's unchanged rows.
                    .removeDuplicates()
                    .start(in: writer) { error in
                        continuation.finish(throwing: error)
                    } onChange: { value in
                        continuation.yield(value)
                    }

                continuation.onTermination = { _ in cancellable.cancel() }
            }
        }
    }

    /// Writes a self-contained copy of the database to `url`, for the backup
    /// and export in SPEC §4.
    ///
    /// `VACUUM INTO` rather than a file copy: it runs inside a transaction,
    /// so the snapshot is consistent even if a write is in flight, and it
    /// produces a single tidy file with no free pages. Any existing file at
    /// `url` is removed first — SQLite refuses to overwrite.
    public func exportSnapshot(to url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: url)
        }

        try writer.writeWithoutTransaction { db in
            try db.execute(sql: "VACUUM INTO ?", arguments: [url.path(percentEncoded: false)])
        }
    }

    /// Removes every record, leaving the schema in place.
    ///
    /// The counterpart to `exportSnapshot(to:)` — the only safe way to offer
    /// this is next to a working backup.
    ///
    /// All three tables are emptied explicitly rather than leaning on the
    /// cascade from `Educations`. The cascade would do it today, but the
    /// intent here is "empty the database", and saying that outright keeps it
    /// true if a table is ever added that no education owns. One transaction,
    /// so a failure part-way leaves the data as it was.
    public func deleteAllRecords() throws {
        try write { db in
            try Grade.deleteAll(db)
            try Subject.deleteAll(db)
            try Education.deleteAll(db)
        }
    }
}

extension Configuration {
    /// Scade's connection settings.
    ///
    /// A `DatabaseQueue` — not a `DatabasePool` — because the pool runs in WAL
    /// mode, and SPEC §5 wants this file to be copyable by iCloud as a single
    /// artifact. Without WAL there are no `-wal`/`-shm` sidecars to sync out
    /// of step with the main file.
    static var scade: Configuration {
        var configuration = Configuration()
        // On by default in GRDB; stated explicitly because the cascade
        // deletes in §2 depend on it.
        configuration.foreignKeysEnabled = true
        return configuration
    }
}
