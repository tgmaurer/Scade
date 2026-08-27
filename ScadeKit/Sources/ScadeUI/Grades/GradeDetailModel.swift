import ScadeKit
import SwiftUI

/// Backs the grade detail screen.
@Observable
final class GradeDetailModel {
    private(set) var item: GradeListItem?

    var isConfirmingDeletion = false
    var errorMessage: String?
    private(set) var wasDeleted = false

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// Follows this grade for as long as the screen is on screen — its own
    /// edits included, so an edit here needs no reload. See
    /// `AppDatabase.observe`.
    func observe(id: Int64?, from repositories: Repositories) async {
        guard let id else { return }

        do {
            for try await item in repositories.database.observeGrade(id: id) {
                self.item = item
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let id = item?.grade.id else { return }

        do {
            try repositories.grades.delete(id: id)
            wasDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
