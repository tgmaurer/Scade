import ScadeKit
import SwiftUI

/// The educations list (SPEC §4): search, filter, create, edit, delete.
///
/// The one list that isn't laid out as a list. There are a handful of
/// educations — several run in parallel, one per institution — so they fit a
/// window all at once, and a single column of them left most of a wide one
/// empty. See `CardGrid` and the §2.5 amendment; the long lists keep their
/// column.
///
/// The layout forks because the delete action does. A grid can't carry
/// `.swipeActions` — those are `List`-only — and it shouldn't want to: swipe
/// to delete is an iOS gesture, and the macOS answer is the context menu the
/// grid uses instead. Neither is the only way out, since the detail screen
/// has a Delete of its own.
struct EducationListScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = EducationListModel()
    @State private var formMode: EducationFormMode?

    var body: some View {
        @Bindable var model = model

        rows
        .navigationTitle("Educations")
        .searchable(text: $model.searchText, prompt: "Search educations")
        .overlay {
            // Not until the first snapshot has arrived: see
            // `hasLoaded`.
            if model.hasLoaded {
                EducationListEmptyState(
                    hasAnyEducations: model.rows.isEmpty == false,
                    hasVisibleRows: model.visibleRows.isEmpty == false,
                    hasActiveFilters: model.hasActiveFilters,
                    onCreate: startCreating,
                    onClearFilters: model.clearFilters
                )
            }
        }
        .toolbar {
            ToolbarItem {
                EducationFilterMenu(
                    completion: $model.completion,
                    institution: $model.institution,
                    institutions: model.institutions
                )
            }

            ToolbarItem {
                Button("New Education", systemImage: "plus", action: startCreating)
                    .accessibilityIdentifier(AccessibilityID.Education.new)
            }
        }
        .sheet(item: $formMode) { mode in
            EducationFormScreen(mode: mode)
        }
        .confirmationDialog(
            "Delete Education?",
            isPresented: $model.isShowingDeletionConfirmation,
            presenting: model.pendingDeletion
        ) { _ in
            Button("Delete", role: .destructive) {
                model.confirmDeletion(from: repositories)
            }
        } message: { row in
            EducationDeletionMessage(
                name: row.education.name,
                subjectCount: row.subjectCount
            )
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(repositories)
        }
    }

    /// macOS: a grid of tiles. iOS: the list it has always been, with the
    /// system's separator between every row taken away — a card and a rule
    /// are two answers to the same question (§2.5).
    @ViewBuilder
    private var rows: some View {
        #if os(macOS)
        CardGrid(items: model.visibleRows) { row in
            NavigationLink(value: row.education) {
                EducationRowView(row: row)
                    // Inside the link, so the whole tile is the click target
                    // rather than the text within it.
                    .cardTile()
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.pendingDeletion = row
                }
            }
        }
        #else
        List {
            ForEach(model.visibleRows) { row in
                NavigationLink(value: row.education) {
                    EducationRowView(row: row)
                        .padding(.vertical, ScadeDesign.rowVerticalPadding)
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = row
                    }
                }
            }
        }
        #endif
    }

    private func startCreating() {
        formMode = .create
    }

}

#Preview {
    NavigationStack {
        EducationListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
