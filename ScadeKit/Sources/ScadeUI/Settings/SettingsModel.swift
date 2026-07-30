import Foundation
import ScadeKit
import SwiftUI

/// Backs the settings screen. Only the export needs any state.
@Observable
@MainActor
final class SettingsModel {
    /// A consistent snapshot written to a temporary file, ready to share.
    private(set) var exportURL: URL?

    /// Only used to phrase the reset confirmation, and to know whether there
    /// is anything to reset — subjects and grades can't outlive an education.
    private(set) var educationCount = 0

    var isShowingResetConfirmation = false

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// Dated so a share sheet's filename says when the backup was taken.
    private var exportFilename: String {
        "Scade-\(CalendarDate.today().iso8601String).sqlite"
    }

    func load(from repositories: Repositories) {
        prepareExport(from: repositories)

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
