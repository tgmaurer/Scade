import ScadeKit
import SwiftUI

/// Backs the grades list.
@Observable
final class GradeListModel {
    private(set) var rows: [GradeListItem] = []
    /// §4 disables grade creation, with a reason, when nothing can hold one.
    private(set) var hasInProgressSubject = false
    private(set) var hasAnySubject = false

    var searchText = ""
    var showsFailingOnly = false

    var pendingDeletion: GradeListItem?
    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var isShowingDeletionConfirmation: Bool {
        get { pendingDeletion != nil }
        set { if newValue == false { pendingDeletion = nil } }
    }

    var hasActiveFilters: Bool { showsFailingOnly }

    var visibleRows: [GradeListItem] {
        rows
            .filter { showsFailingOnly == false || $0.grade.isFailing }
            .matching(searchQuery: searchText)
    }

    var creationBlockedReason: LocalizedStringKey? {
        if hasAnySubject == false {
            "Add a subject before adding grades."
        } else if hasInProgressSubject == false {
            "Every subject is completed. Reopen one to add a grade."
        } else {
            nil
        }
    }

    func load(from repositories: Repositories) {
        do {
            rows = try repositories.grades.allListItems()
            let subjects = try repositories.subjects.all()
            hasAnySubject = subjects.isEmpty == false
            hasInProgressSubject = subjects.contains { $0.completed == false }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearFilters() {
        showsFailingOnly = false
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let row = pendingDeletion, let id = row.grade.id else { return }
        pendingDeletion = nil

        do {
            try repositories.grades.delete(id: id)
            load(from: repositories)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
