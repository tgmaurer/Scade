import SwiftUI

/// What the subjects list shows when it has nothing to show.
struct SubjectListEmptyState: View {
    let hasAnySubjects: Bool
    let hasVisibleRows: Bool
    let hasActiveFilters: Bool
    let creationBlockedReason: LocalizedStringKey?
    let onCreate: () -> Void
    let onClearFilters: () -> Void

    var body: some View {
        if hasVisibleRows {
            EmptyView()
        } else if hasAnySubjects == false {
            ContentUnavailableView {
                Label("No Subjects", systemImage: "books.vertical")
            } description: {
                // §4: say why creating isn't possible rather than offering a
                // button that does nothing.
                if let creationBlockedReason {
                    Text(creationBlockedReason)
                } else {
                    Text("Add a subject to start recording grades.")
                }
            } actions: {
                if creationBlockedReason == nil {
                    Button("New Subject", systemImage: "plus", action: onCreate)
                }
            }
        } else if hasActiveFilters {
            ContentUnavailableView {
                Label("No Matches", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No subjects match the current filters.")
            } actions: {
                Button("Clear Filters", action: onClearFilters)
            }
        } else {
            ContentUnavailableView.search
        }
    }
}

#Preview {
    SubjectListEmptyState(
        hasAnySubjects: false,
        hasVisibleRows: false,
        hasActiveFilters: false,
        creationBlockedReason: "Add an education before adding subjects.",
        onCreate: {},
        onClearFilters: {}
    )
}
