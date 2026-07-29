import ScadeKit
import SwiftUI

/// The grades list (SPEC §4).
struct GradeListScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = GradeListModel()
    @State private var formMode: GradeFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            ForEach(model.visibleRows) { item in
                NavigationLink(value: item.grade) {
                    GradeRowView(item: item)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = item
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .searchable(text: $model.searchText, prompt: "Search grades")
        .overlay {
            GradeListEmptyState(
                hasAnyGrades: model.rows.isEmpty == false,
                hasVisibleRows: model.visibleRows.isEmpty == false,
                hasActiveFilters: model.hasActiveFilters,
                creationBlockedReason: model.creationBlockedReason,
                onCreate: startCreating,
                onClearFilters: model.clearFilters
            )
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $model.showsFailingOnly) {
                    Label(
                        "Failing Only",
                        systemImage: model.showsFailingOnly
                            ? "exclamationmark.triangle.fill"
                            : "exclamationmark.triangle"
                    )
                }
                .toggleStyle(.button)
            }

            ToolbarItem {
                Button("New Grade", systemImage: "plus", action: startCreating)
                    .disabled(model.creationBlockedReason != nil)
                    .help(model.creationBlockedReason ?? "")
            }
        }
        .sheet(item: $formMode, onDismiss: reload) { mode in
            GradeFormScreen(mode: mode)
        }
        .confirmationDialog(
            "Delete Grade?",
            isPresented: $model.isShowingDeletionConfirmation,
            presenting: model.pendingDeletion
        ) { _ in
            Button("Delete", role: .destructive) {
                model.confirmDeletion(from: repositories)
            }
        } message: { item in
            GradeDeletionMessage(item: item)
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
        GradeListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
