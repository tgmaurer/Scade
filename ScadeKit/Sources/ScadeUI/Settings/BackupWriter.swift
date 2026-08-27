import Foundation
import ScadeKit

/// Writes a complete backup into a folder.
///
/// Two things at once, deliberately: the `.sqlite` snapshot, which is the
/// only file that restores the app exactly, and the three CSV tables, which
/// are the only ones a spreadsheet can read. Either alone is half a backup —
/// one you can't open, or one you can't put back — and doing both on the
/// same click means it can't be half-done.
enum BackupWriter {
    /// One folder per day. Clicking twice in an afternoon refreshes it
    /// rather than leaving a drift of near-identical copies; yesterday's is
    /// untouched.
    static func folderName(on date: CalendarDate = .today()) -> String {
        "Scade Backup \(date.iso8601String)"
    }

    static let databaseFilename = "scade.sqlite"

    /// Writes into `destination` and returns the folder it made.
    @discardableResult
    static func write(
        into destination: URL,
        from repositories: Repositories
    ) throws -> URL {
        let folder = destination.appending(path: folderName(), directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        try repositories.database.exportSnapshot(
            to: folder.appending(path: databaseFilename, directoryHint: .notDirectory)
        )

        try write(BackupTables.educations(try repositories.educations.all()), to: folder, as: "educations.csv")
        try write(BackupTables.subjects(try repositories.subjects.all()), to: folder, as: "subjects.csv")
        try write(BackupTables.grades(try repositories.grades.all()), to: folder, as: "grades.csv")

        return folder
    }

    private static func write(_ text: String, to folder: URL, as name: String) throws {
        try text.write(
            to: folder.appending(path: name, directoryHint: .notDirectory),
            atomically: true,
            encoding: .utf8
        )
    }
}
