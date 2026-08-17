import ScadeKit
import SwiftUI

/// The subjects list (SPEC §4).
struct SubjectListScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = SubjectListModel()
    @State private var formMode: SubjectFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            ForEach(model.visibleRows.enumerated(), id: \.element.id) { index, row in
                NavigationLink(value: row.subject) {
                    SubjectRowView(row: row)
                        .padding(.vertical, ScadeDesign.rowVerticalPadding)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = row
                    }
                }
                // Right-click is how a Mac deletes a row; swipe is the iOS
                // gesture above. Same choice as the educations grid.
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = row
                    }
                }
                // One card for the whole list rather than one per row: these
                // are rows of a list, not objects that stand alone, and iOS's
                // own `.insetGrouped` treats a single long section exactly
                // this way. The card is what replaces the system separators —
                // see §2.5.
                .cardRow(CardRowPosition(index: index, count: model.visibleRows.count))
            }
        }
        .groupedListStyle()
        .navigationTitle("Subjects")
        .searchable(text: $model.searchText, prompt: "Search subjects")
        .overlay {
            SubjectListEmptyState(
                hasAnySubjects: model.rows.isEmpty == false,
                hasVisibleRows: model.visibleRows.isEmpty == false,
                hasActiveFilters: model.hasActiveFilters,
                creationBlockedReason: model.creationBlockedReason,
                onCreate: startCreating,
                onClearFilters: model.clearFilters
            )
        }
        .toolbar {
            ToolbarItem {
                SubjectFilterMenu(
                    completion: $model.completion,
                    institution: $model.institution,
                    semester: $model.semester,
                    institutions: model.institutions,
                    semesters: model.availableSemesters
                )
            }

            ToolbarItem {
                Button("New Subject", systemImage: "plus", action: startCreating)
                    .accessibilityIdentifier(AccessibilityID.Subject.new)
                    .disabled(model.creationBlockedReason != nil)
                    .help(model.creationBlockedReason ?? "")
            }
        }
        .sheet(item: $formMode) { mode in
            SubjectFormScreen(mode: mode)
        }
        .confirmationDialog(
            "Delete Subject?",
            isPresented: $model.isShowingDeletionConfirmation,
            presenting: model.pendingDeletion
        ) { _ in
            Button("Delete", role: .destructive) {
                model.confirmDeletion(from: repositories)
            }
        } message: { row in
            SubjectDeletionMessage(name: row.subject.name, gradeCount: row.gradeCount)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(repositories)
        }
    }

    private func startCreating() {
        formMode = .create()
    }

}

#Preview {
    NavigationStack {
        SubjectListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
