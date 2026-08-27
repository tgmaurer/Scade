import ScadeKit
import SwiftUI

/// Backs the subjects list.
@Observable
final class SubjectListModel {
    /// Whether the first snapshot has arrived.
    ///
    /// An observation is asynchronous, so a screen is briefly on screen with
    /// nothing in it — and the empty state would flash "nothing here yet"
    /// every time you switched sections, before the data it was wrong about
    /// arrived a frame later. Nothing at all is the honest thing to draw
    /// while there is nothing to say (SPEC-POLISH §2.7).
    private(set) var hasLoaded = false

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

    /// Follows the database for as long as the screen is on screen. See
    /// `AppDatabase.observe`.
    func observe(_ repositories: Repositories) async {
        do {
            for try await data in repositories.database.observeSubjectList() {
                apply(data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ data: SubjectListData) {
        hasLoaded = true

        rows = data.summaries.map(SubjectRow.init)
        institutions = data.institutions
        hasInProgressEducation = data.hasInProgressEducation
        hasAnyEducation = data.hasAnyEducation

        if let institution, institutions.contains(institution) == false {
            self.institution = nil
        }
        if let semester, availableSemesters.contains(semester) == false {
            self.semester = nil
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
            // No reload: the observation publishes the deletion.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
