import ScadeKit
import SwiftUI

/// The educations list (SPEC §4): search, filter, create, edit, delete.
struct EducationListScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = EducationListModel()
    @State private var formMode: EducationFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            ForEach(model.visibleRows) { row in
                NavigationLink(value: row.education) {
                    EducationRowView(row: row)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = row
                    }
                }
            }
        }
        .navigationTitle("Educations")
        .searchable(text: $model.searchText, prompt: "Search educations")
        .overlay {
            EducationListEmptyState(
                hasAnyEducations: model.rows.isEmpty == false,
                hasVisibleRows: model.visibleRows.isEmpty == false,
                hasActiveFilters: model.hasActiveFilters,
                onCreate: startCreating,
                onClearFilters: model.clearFilters
            )
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
        .sheet(item: $formMode, onDismiss: reload) { mode in
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
        .onAppear(perform: reload)
    }

    private func startCreating() {
        formMode = .create
    }

    private func reload() {
        model.load(from: repositories)
    }
}

#Preview {
    NavigationStack {
        EducationListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
