import ScadeKit
import SwiftUI

/// Backs the education detail screen.
@Observable
final class EducationDetailModel {
    private(set) var summary: EducationSummary?
    /// Worked out once per load rather than on every `body` pass.
    private(set) var average: Double?

    var isConfirmingDeletion = false
    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// True once the education has been deleted, so the screen knows to pop
    /// rather than sit on a record that no longer exists.
    private(set) var wasDeleted = false

    /// Follows this education for as long as the screen is on screen — its
    /// own edits included, so an edit here needs no reload. See
    /// `AppDatabase.observe`.
    func observe(id: Int64?, from repositories: Repositories) async {
        guard let id else { return }

        do {
            for try await summary in repositories.database.observeEducation(id: id) {
                self.summary = summary
                average = summary.map { GradeCalculator.educationAverage(of: $0.subjects) } ?? nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let id = summary?.education.id else { return }

        do {
            try repositories.educations.delete(id: id)
            wasDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
