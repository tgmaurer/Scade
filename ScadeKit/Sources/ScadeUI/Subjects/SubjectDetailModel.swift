import ScadeKit
import SwiftUI

/// Backs the subject detail screen.
@Observable
@MainActor
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

    func load(id: Int64?, from repositories: Repositories) {
        guard let id else { return }

        do {
            summary = try repositories.subjects.summary(id: id)
            average = summary.map { GradeCalculator.subjectAverage(of: $0.grades) } ?? nil
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
