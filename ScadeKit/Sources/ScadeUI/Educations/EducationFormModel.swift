import ScadeKit
import SwiftUI

/// Holds what the education form has been typed into, and decides whether it
/// can be saved.
@Observable
final class EducationFormModel {
    let mode: EducationFormMode

    // The validated fields revalidate as they change, so an error clears the
    // moment it's fixed instead of waiting for the next save attempt. `didSet`
    // doesn't fire during `init`, which is what keeps a fresh form quiet.
    var name: String { didSet { revalidate() } }
    var details: String { didSet { revalidate() } }
    var startDate: Date { didSet { revalidate() } }
    var endDate: Date { didSet { revalidate() } }
    var semesters: Int { didSet { revalidate() } }

    var institution: String
    var completed: Bool

    /// Empty until the first save attempt, so the form doesn't scold someone
    /// for fields they haven't reached yet.
    private(set) var errors: [ValidationError] = []
    private var hasAttemptedSave = false

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    init(mode: EducationFormMode) {
        self.mode = mode

        switch mode {
        case .create:
            // Defaults from §4. The dates open on the school year rather than
            // on today, since an education almost never starts mid-week.
            let year = AcademicYear.containing(.today())
            name = ""
            institution = ""
            details = ""
            startDate = year.lowerBound.startOfDay()
            endDate = year.upperBound.startOfDay()
            semesters = 2
            completed = false

        case .edit(let education):
            name = education.name
            institution = education.institution ?? ""
            details = education.description ?? ""
            startDate = education.startDate.startOfDay()
            endDate = education.endDate.startOfDay()
            semesters = education.semesters
            completed = education.completed
        }
    }

    /// The record as currently typed.
    ///
    /// `completed` is only carried over when editing — on create the
    /// repository forces it false anyway, and the form doesn't offer it.
    private var draft: Education {
        var education = Education(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: details.isEmpty ? nil : details,
            semesters: semesters,
            startDate: CalendarDate(startDate),
            endDate: CalendarDate(endDate),
            institution: institution.isEmpty ? nil : institution,
            completed: mode.isEditing ? completed : false
        )

        if case .edit(let existing) = mode {
            education.id = existing.id
        }
        return education
    }

    func message(for field: ValidationField) -> String? {
        errors.message(for: field)
    }

    /// Re-checks the form once the user has already tried to save, so errors
    /// clear as they're fixed rather than lingering until the next attempt.
    func revalidate() {
        guard hasAttemptedSave else { return }
        errors = EducationValidator.validate(draft)
    }

    /// Returns `true` when the education was written and the form can close.
    func save(to repositories: Repositories) -> Bool {
        hasAttemptedSave = true
        errors = EducationValidator.validate(draft)
        guard errors.isEmpty else { return false }

        do {
            switch mode {
            case .create:
                try repositories.educations.create(draft)
            case .edit:
                try repositories.educations.update(draft)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
