import ScadeKit
import SwiftUI

/// Backs the subjects list.
@Observable
final class SubjectListModel {
    private(set) var rows: [SubjectRow] = []
    private(set) var institutions: [String] = []
    /// Whether any education is still in progress — §4 disables subject
    /// creation, with a reason, when none is.
    private(set) var hasInProgressEducation = false
    private(set) var hasAnyEducation = false

    var searchText = ""
    var completion: CompletionFilter = .all
    var institution: String?
    var semester: Int?

    var pendingDeletion: SubjectRow?
    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var isShowingDeletionConfirmation: Bool {
        get { pendingDeletion != nil }
        set { if newValue == false { pendingDeletion = nil } }
    }

    /// The semesters actually present, so the filter can't offer an empty one.
    var availableSemesters: [Int] {
        Array(Set(rows.map(\.subject.semester))).sorted()
    }

    var hasActiveFilters: Bool {
        completion != .all || institution != nil || semester != nil
    }

    var visibleRows: [SubjectRow] {
        rows
            .filter { completion.matches(completed: $0.subject.completed) }
            .filter { institution == nil || $0.education.institution == institution }
            .filter { semester == nil || $0.subject.semester == semester }
            .matching(searchQuery: searchText)
    }

    /// Why the create button is unavailable, or `nil` when it isn't.
    var creationBlockedReason: LocalizedStringKey? {
        if hasAnyEducation == false {
            "Add an education before adding subjects."
        } else if hasInProgressEducation == false {
            "Every education is completed. Reopen one to add a subject."
        } else {
            nil
        }
    }

    func load(from repositories: Repositories) {
        do {
            rows = try repositories.subjects.allSummaries().map(SubjectRow.init)
            institutions = try repositories.educations.distinctInstitutions()
            hasInProgressEducation = try repositories.educations.inProgress().isEmpty == false
            hasAnyEducation = try repositories.educations.count() > 0

            if let institution, institutions.contains(institution) == false {
                self.institution = nil
            }
            if let semester, availableSemesters.contains(semester) == false {
                self.semester = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearFilters() {
        completion = .all
        institution = nil
        semester = nil
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let row = pendingDeletion, let id = row.subject.id else { return }
        pendingDeletion = nil

        do {
            try repositories.subjects.delete(id: id)
            load(from: repositories)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
