import ScadeKit
import SwiftUI

/// Backs the subject detail screen.
@Observable
final class SubjectDetailModel {
    private(set) var summary: SubjectSummary?
    /// Worked out once per load rather than on every `body` pass.
    private(set) var average: Double?

    var isConfirmingDeletion = false
    var errorMessage: String?
    private(set) var wasDeleted = false

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    /// Follows this subject for as long as the screen is on screen — its own
    /// edits included, so a rename here needs no reload. See
    /// `AppDatabase.observe`.
    func observe(id: Int64?, from repositories: Repositories) async {
        guard let id else { return }

        do {
            for try await summary in repositories.database.observeSubject(id: id) {
                self.summary = summary
                average = summary.map { GradeCalculator.subjectAverage(of: $0.grades) } ?? nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let id = summary?.subject.id else { return }

        do {
            try repositories.subjects.delete(id: id)
            wasDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
