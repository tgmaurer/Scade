import Foundation
import ScadeKit
import SwiftUI

/// Backs the settings screen. Only the export needs any state.
@Observable
final class SettingsModel {
    /// A consistent snapshot written to a temporary file, ready to share.
    private(set) var exportURL: URL?

    /// Only used to phrase the reset confirmation, and to know whether there
    /// is anything to reset — subjects and grades can't outlive an education.
    private(set) var educationCount = 0

    var isShowingResetConfirmation = false

    var errorMessage: String?

    #if os(macOS)
    /// Where backups go, if a folder has been chosen (`BackupFolder`).
    private(set) var backupFolder: URL?

    /// When the last one was written, and where it landed — the second is
    /// only known for a backup taken this session, which is why "Show in
    /// Finder" appears after taking one rather than always.
    private(set) var lastBackup: Date?
    private(set) var lastBackupFolder: URL?
    #endif

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// Dated so a share sheet's filename says when the backup was taken.
    private var exportFilename: String {
        "Scade-\(CalendarDate.today().iso8601String).sqlite"
    }

    /// The one screen still on fetch-on-appear, deliberately.
    ///
    /// Loading here *writes a file* — the export snapshot — so an observation
    /// would rewrite it on every change anywhere in the database. Settings
    /// also has nothing pushed on top of it, so the staleness that drove the
    /// rest of the app onto `AppDatabase.observe` can't happen here: the only
    /// thing that changes the count while it's open is the button below,
    /// which reloads.
    func load(from repositories: Repositories) {
        prepareExport(from: repositories)

        #if os(macOS)
        backupFolder = BackupFolder.current
        lastBackup = BackupFolder.lastBackup
        #endif

        do {
            educationCount = try repositories.educations.count()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Writes the snapshot the share sheet hands off.
    ///
    /// Runs when settings appears rather than behind a "prepare" button —
    /// the file is small, and a share control that's already armed beats a
    /// two-step dance.
    private func prepareExport(from repositories: Repositories) {
        let url = FileManager.default.temporaryDirectory
            .appending(path: exportFilename, directoryHint: .notDirectory)

        do {
            try repositories.database.exportSnapshot(to: url)
            exportURL = url
        } catch {
            exportURL = nil
            errorMessage = error.localizedDescription
        }
    }

    #if os(macOS)
    /// Asks for a folder, and remembers it. Cancelling leaves the old one.
    func chooseBackupFolder() {
        guard let chosen = BackupFolder.choose() else { return }
        backupFolder = chosen
    }

    /// Writes the snapshot and the three CSV tables into the chosen folder.
    func backUpNow(from repositories: Repositories) {
        guard let folder = backupFolder else { return }

        do {
            let written = try BackupFolder.withAccess(to: folder) {
                try BackupWriter.write(into: $0, from: repositories)
            }

            BackupFolder.recordBackup()
            lastBackup = BackupFolder.lastBackup
            lastBackupFolder = written
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif

    /// Empties the database.
    ///
    /// Reloads afterwards rather than assuming success: the share link would
    /// otherwise keep offering a snapshot of data that no longer exists,
    /// which is exactly the moment someone would tap it.
    func deleteAllData(from repositories: Repositories) {
        do {
            try repositories.database.deleteAllRecords()
        } catch {
            errorMessage = error.localizedDescription
        }

        load(from: repositories)
    }
}
