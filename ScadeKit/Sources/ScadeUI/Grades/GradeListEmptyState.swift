import SwiftUI

/// What the grades list shows when it has nothing to show.
struct GradeListEmptyState: View {
    let hasAnyGrades: Bool
    let hasVisibleRows: Bool
    let hasActiveFilters: Bool
    let creationBlockedReason: LocalizedStringKey?
    let onCreate: () -> Void
    let onClearFilters: () -> Void

    var body: some View {
        if hasVisibleRows {
            EmptyView()
        } else if hasAnyGrades == false {
            ContentUnavailableView {
                Label("No Grades", systemImage: "list.number")
            } description: {
                if let creationBlockedReason {
                    Text(creationBlockedReason)
                } else {
                    Text("Record a grade to start tracking an average.")
                }
            } actions: {
                if creationBlockedReason == nil {
                    Button("New Grade", systemImage: "plus", action: onCreate)
                }
            }
        } else if hasActiveFilters {
            ContentUnavailableView {
                Label("Nothing Failing", systemImage: "checkmark.circle")
            } description: {
                Text("No grades are below the passing mark.")
            } actions: {
                Button("Show All Grades", action: onClearFilters)
            }
        } else {
            ContentUnavailableView.search
        }
    }
}
