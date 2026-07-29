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
