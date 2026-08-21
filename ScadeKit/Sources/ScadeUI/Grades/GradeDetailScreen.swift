import ScadeKit
import SwiftUI

/// One grade in full (SPEC §4).
struct GradeDetailScreen: View {
    let grade: Grade

    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model = GradeDetailModel()
    @State private var formMode: GradeFormMode?

    var body: some View {
        @Bindable var model = model

        DetailScroll {
            if let item = model.item {
                DetailSection {
                    DetailSectionText {
                        GradeDetailHeader(item: item)
                    }
                }

                if let details = item.grade.description, details.isEmpty == false {
                    // A card of its own, in full — the one place the whole
                    // description lives. Every list and grid holds it to a
                    // line (§2.4).
                    DetailSection(title: "Description") {
                        DetailSectionText {
                            Text(details)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        // The most specific thing that names it, the same rule the grades
        // list heads a tile with: what the grade was for, or failing that
        // the day it happened. It read "Grade" on every one of them.
        .navigationTitle(title)
        .accessibilityIdentifier(AccessibilityID.Grade.detail)
        .toolbar {
            ToolbarItem {
                Button("Edit", systemImage: "pencil", action: startEditing)
            }

            ToolbarItem {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.isConfirmingDeletion = true
                }
                .confirmationDialog(
                    "Delete Grade?",
                    isPresented: $model.isConfirmingDeletion,
                    presenting: model.item
                ) { _ in
                    Button("Delete", role: .destructive) {
                        model.confirmDeletion(from: repositories)
                    }
                } message: { item in
                    GradeDeletionMessage(item: item)
                }
            }
        }
        .sheet(item: $formMode) { mode in
            GradeFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(id: grade.id, from: repositories)
        }
        .onChange(of: model.wasDeleted) {
            if model.wasDeleted {
                dismiss()
            }
        }
    }

    private var title: String {
        if let details = model.item?.grade.description, details.isEmpty == false {
            return details
        }

        let date = model.item?.grade.date ?? grade.date
        return date.startOfDay().formatted(.dateTime.day().month().year())
    }

    private func startEditing() {
        guard let grade = model.item?.grade else { return }
        formMode = .edit(grade)
    }

}
