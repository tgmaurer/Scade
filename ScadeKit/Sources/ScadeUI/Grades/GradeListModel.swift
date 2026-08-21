import ScadeKit
import SwiftUI

/// Backs the grades list.
@Observable
final class GradeListModel {
    /// Whether the first snapshot has arrived.
    ///
    /// An observation is asynchronous, so a screen is briefly on screen with
    /// nothing in it — and the empty state would flash "nothing here yet"
    /// every time you switched sections, before the data it was wrong about
    /// arrived a frame later. Nothing at all is the honest thing to draw
    /// while there is nothing to say (SPEC-POLISH §2.7).
    private(set) var hasLoaded = false

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

    /// Follows the database for as long as the screen is on screen. See
    /// `AppDatabase.observe`.
    func observe(_ repositories: Repositories) async {
        do {
            for try await data in repositories.database.observeGradeList() {
                apply(data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ data: GradeListData) {
        hasLoaded = true

        rows = data.items
        hasAnySubject = data.subjects.isEmpty == false
        hasInProgressSubject = data.subjects.contains { $0.completed == false }
    }

    func clearFilters() {
        showsFailingOnly = false
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let row = pendingDeletion, let id = row.grade.id else { return }
        pendingDeletion = nil

        do {
            try repositories.grades.delete(id: id)
            // No reload: the observation publishes the deletion.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
