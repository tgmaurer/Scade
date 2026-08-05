import ScadeKit
import SwiftUI

/// Holds what the subject form has been typed into, and decides whether it
/// can be saved.
@Observable
final class SubjectFormModel {
    let mode: SubjectFormMode

    var educationId: Int64? { didSet { revalidate() } }
    var name: String { didSet { revalidate() } }
    var details: String { didSet { revalidate() } }
    var semester: Int { didSet { revalidate() } }
    /// Entered as a percentage, stored as a multiplier (§3.3).
    var weightPercent: Double { didSet { revalidate() } }
    var completed: Bool

    /// The educations the picker may offer: in-progress ones, plus the
    /// subject's own even if it has since been completed (§4).
    private(set) var educations: [Education] = []

    private(set) var errors: [ValidationError] = []
    private var hasAttemptedSave = false

    /// Raised by the unique index rather than by validation — checking for it
    /// in Swift first would reopen the race the index closed.
    private(set) var hasNameConflict = false

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var selectedEducation: Education? {
        educations.first { $0.id == educationId }
    }

    init(mode: SubjectFormMode) {
        self.mode = mode

        switch mode {
        case .create(let educationId, let semester):
            self.educationId = educationId
            name = ""
            details = ""
            self.semester = semester ?? 1
            weightPercent = 100
            completed = false

        case .edit(let subject):
            educationId = subject.educationId
            name = subject.name
            details = subject.description ?? ""
            semester = subject.semester
            weightPercent = subject.weight * 100
            completed = subject.completed
        }
    }

    private var draft: Subject {
        var subject = Subject(
            educationId: educationId ?? 0,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: details.isEmpty ? nil : details,
            semester: semester,
            weight: weightPercent / 100,
            completed: mode.isEditing ? completed : false
        )

        if case .edit(let existing) = mode {
            subject.id = existing.id
        }
        return subject
    }

    func message(for field: ValidationField) -> String? {
        if field == .name, hasNameConflict {
            return "Another subject in this education already uses this name and semester."
        }
        return errors.message(for: field)
    }

    func load(from repositories: Repositories) {
        do {
            var available = try repositories.educations.inProgress()

            // Editing a subject whose education has since been completed must
            // not silently move it somewhere else.
            if case .edit(let subject) = mode,
               available.contains(where: { $0.id == subject.educationId }) == false,
               let owner = try repositories.educations.find(id: subject.educationId) {
                available.append(owner)
            }

            educations = available
            if educationId == nil {
                educationId = available.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revalidate() {
        hasNameConflict = false
        guard hasAttemptedSave, let education = selectedEducation else { return }
        errors = SubjectValidator.validate(draft, in: education)
    }

    /// Returns `true` when the subject was written and the form can close.
    func save(to repositories: Repositories) -> Bool {
        hasAttemptedSave = true
        hasNameConflict = false

        guard let education = selectedEducation else {
            errorMessage = "Choose an education for this subject."
            return false
        }

        errors = SubjectValidator.validate(draft, in: education)
        guard errors.isEmpty else { return false }

        do {
            switch mode {
            case .create:
                try repositories.subjects.create(draft)
            case .edit:
                try repositories.subjects.update(draft)
            }
            return true
        } catch RepositoryError.duplicateSubject {
            hasNameConflict = true
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
