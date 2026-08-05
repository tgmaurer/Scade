import ScadeKit
import SwiftUI

/// Holds what the grade form has been typed into, and decides whether it can
/// be saved.
@Observable
final class GradeFormModel {
    let mode: GradeFormMode

    var subjectId: Int64? { didSet { revalidate() } }
    var value: Double { didSet { revalidate() } }
    /// Entered as a percentage, stored as a multiplier (§3.3).
    var weightPercent: Double { didSet { revalidate() } }
    var date: Date { didSet { revalidate() } }
    var details: String { didSet { revalidate() } }

    /// In-progress subjects, plus the grade's own even if it has since been
    /// completed (§4). Carries the education because the date rule in §3.4
    /// belongs to the education, not the subject.
    private(set) var subjects: [SubjectListItem] = []

    private(set) var errors: [ValidationError] = []
    private var hasAttemptedSave = false

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var selectedSubject: SubjectListItem? {
        subjects.first { $0.subject.id == subjectId }
    }

    init(mode: GradeFormMode) {
        self.mode = mode

        switch mode {
        case .create(let subjectId):
            self.subjectId = subjectId
            value = GradingScale.passingThreshold
            weightPercent = 100
            date = CalendarDate.today().startOfDay()
            details = ""

        case .edit(let grade):
            subjectId = grade.subjectId
            value = grade.value
            weightPercent = grade.weight * 100
            date = grade.date.startOfDay()
            details = grade.description ?? ""
        }
    }

    private var draft: Grade {
        var grade = Grade(
            subjectId: subjectId ?? 0,
            value: value,
            weight: weightPercent / 100,
            description: details.isEmpty ? nil : details,
            date: CalendarDate(date)
        )

        if case .edit(let existing) = mode {
            grade.id = existing.id
        }
        return grade
    }

    func message(for field: ValidationField) -> String? {
        errors.message(for: field)
    }

    func load(from repositories: Repositories) {
        do {
            var available = try repositories.subjects.allListItems()
                .filter { $0.subject.completed == false }

            if case .edit(let grade) = mode,
               available.contains(where: { $0.subject.id == grade.subjectId }) == false,
               let owner = try repositories.subjects.summary(id: grade.subjectId) {
                available.append(
                    SubjectListItem(subject: owner.subject, education: owner.education)
                )
            }

            subjects = available
            if subjectId == nil {
                subjectId = available.first?.subject.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revalidate() {
        guard hasAttemptedSave, let education = selectedSubject?.education else { return }
        errors = GradeValidator.validate(draft, in: education)
    }

    /// Returns `true` when the grade was written and the form can close.
    func save(to repositories: Repositories) -> Bool {
        hasAttemptedSave = true

        guard let education = selectedSubject?.education else {
            errorMessage = "Choose a subject for this grade."
            return false
        }

        errors = GradeValidator.validate(draft, in: education)
        guard errors.isEmpty else { return false }

        do {
            switch mode {
            case .create:
                try repositories.grades.create(draft)
            case .edit:
                try repositories.grades.update(draft)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
