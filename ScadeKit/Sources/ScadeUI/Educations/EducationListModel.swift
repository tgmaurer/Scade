import ScadeKit
import SwiftUI

/// Backs the educations list: what's loaded, what's filtered, what's pending
/// deletion.
@Observable
final class EducationListModel {
    /// Everything in the database, newest-created first (§3.6). Search and
    /// filters narrow this without reordering it.
    private(set) var rows: [EducationRow] = []
    private(set) var institutions: [String] = []

    var searchText = ""
    var completion: CompletionFilter = .all
    var institution: String?

    var pendingDeletion: EducationRow?
    var errorMessage: String?

    /// Bindable form of `errorMessage`, so the alert doesn't need a
    /// hand-rolled `Binding(get:set:)` in the view.
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var isShowingDeletionConfirmation: Bool {
        get { pendingDeletion != nil }
        set { if newValue == false { pendingDeletion = nil } }
    }

    /// The rows that survive the filter controls and the search field.
    ///
    /// Order is inherited from `rows` — §3.6 wants the top-level list
    /// unaffected by search.
    var visibleRows: [EducationRow] {
        rows
            .filter { completion.matches(completed: $0.education.completed) }
            .filter { institution == nil || $0.education.institution == institution }
            .matching(searchQuery: searchText)
    }

    var hasActiveFilters: Bool {
        completion != .all || institution != nil
    }

    /// Follows the database for as long as the screen is on screen.
    ///
    /// Runs until cancelled, which SwiftUI does when the `task` modifier's
    /// view goes away. See `AppDatabase.observe`.
    func observe(_ repositories: Repositories) async {
        do {
            for try await data in repositories.database.observeEducationList() {
                apply(data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ data: EducationListData) {
        rows = data.summaries.map(EducationRow.init)
        institutions = data.institutions

        // An institution can stop existing while its filter is active.
        if let institution, institutions.contains(institution) == false {
            self.institution = nil
        }
    }

    func clearFilters() {
        completion = .all
        institution = nil
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let row = pendingDeletion, let id = row.education.id else { return }
        pendingDeletion = nil

        do {
            try repositories.educations.delete(id: id)
            // No reload: the observation publishes the deletion.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
