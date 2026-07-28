import Foundation
import ScadeKit
import SwiftUI

/// Backs the settings screen. Only the export needs any state.
@Observable
@MainActor
final class SettingsModel {
    /// A consistent snapshot written to a temporary file, ready to share.
    private(set) var exportURL: URL?

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// Dated so a share sheet's filename says when the backup was taken.
    private var exportFilename: String {
        "Scade-\(CalendarDate.today().iso8601String).sqlite"
    }

    /// Writes the snapshot the share sheet hands off.
    ///
    /// Runs when settings appears rather than behind a "prepare" button —
    /// the file is small, and a share control that's already armed beats a
    /// two-step dance.
    func prepareExport(from repositories: Repositories) {
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
}
