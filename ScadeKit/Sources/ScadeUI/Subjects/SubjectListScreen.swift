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
                // macOS draws a link row's pressed state as an accent fill
                // across the *whole* row, while the card behind it is inset by
                // the window margin — so pressing a row lit two indigo strips
                // either side of the card and nothing under it. `.plain` gives
                // up that fill; the card's own hover is the feedback, and it
                // is the right width by construction.
                //
                // macOS only: iOS's link row draws no such fill, and it does
                // draw the disclosure chevron, which is worth keeping.
                #if os(macOS)
                .buttonStyle(.plain)
                #endif
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
                .cardRow(
                    CardRowPosition(index: index, count: model.visibleRows.count),
                    maximumWidth: ScadeDesign.maximumRowWidth
                )
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
