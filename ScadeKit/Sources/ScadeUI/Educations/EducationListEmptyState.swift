import SwiftUI

/// What the educations list shows when it has nothing to show.
///
/// Three different nothings, which need three different answers: no data at
/// all, nothing matching the filters, and nothing matching the search.
struct EducationListEmptyState: View {
    let hasAnyEducations: Bool
    let hasVisibleRows: Bool
    let hasActiveFilters: Bool
    let onCreate: () -> Void
    let onClearFilters: () -> Void

    var body: some View {
        if hasVisibleRows {
            EmptyView()
        } else if hasAnyEducations == false {
            ContentUnavailableView {
                Label("No Educations", systemImage: "graduationcap")
            } description: {
                Text("Add an education to start tracking grades.")
            } actions: {
                Button("New Education", systemImage: "plus", action: onCreate)
            }
        } else if hasActiveFilters {
            ContentUnavailableView {
                Label("No Matches", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No educations match the current filters.")
            } actions: {
                Button("Clear Filters", action: onClearFilters)
            }
        } else {
            // Fills in the search term the user typed by itself.
            ContentUnavailableView.search
        }
    }
}

#Preview {
    EducationListEmptyState(
        hasAnyEducations: false,
        hasVisibleRows: false,
        hasActiveFilters: false,
        onCreate: {},
        onClearFilters: {}
    )
}
