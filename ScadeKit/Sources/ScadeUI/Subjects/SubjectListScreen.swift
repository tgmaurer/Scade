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
            ForEach(model.visibleRows) { row in
                NavigationLink(value: row.subject) {
                    SubjectRowView(row: row)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = row
                    }
                }
            }
        }
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
                    .disabled(model.creationBlockedReason != nil)
                    .help(model.creationBlockedReason ?? "")
            }
        }
        .sheet(item: $formMode, onDismiss: reload) { mode in
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
        .onAppear(perform: reload)
    }

    private func startCreating() {
        formMode = .create()
    }

    private func reload() {
        model.load(from: repositories)
    }
}

#Preview {
    NavigationStack {
        SubjectListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
