import ScadeKit
import SwiftUI

/// One subject in full, with its grades (SPEC §4).
struct SubjectDetailScreen: View {
    let subject: Subject

    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model = SubjectDetailModel()
    @State private var formMode: SubjectFormMode?
    @State private var gradeFormMode: GradeFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            if let summary = model.summary {
                SubjectSummarySection(summary: summary, average: model.average)

                Section("Grades") {
                    if summary.grades.isEmpty {
                        Text("No grades yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summary.grades) { grade in
                            NavigationLink(value: grade) {
                                GradeRowView(
                                    item: GradeListItem(
                                        grade: grade,
                                        subject: summary.subject,
                                        education: summary.education
                                    ),
                                    showsContext: false
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(model.summary?.subject.name ?? subject.name)
        .accessibilityIdentifier(AccessibilityID.Subject.detail)
        .toolbar {
            ToolbarItem {
                // §4 hides quick-add on a completed subject.
                Button("New Grade", systemImage: "plus", action: startAddingGrade)
                    .disabled(model.summary?.subject.completed ?? true)
            }

            ToolbarItem {
                Button("Edit", systemImage: "pencil", action: startEditing)
                    .accessibilityIdentifier(AccessibilityID.Subject.edit)
            }

            ToolbarItem {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.isConfirmingDeletion = true
                }
                .confirmationDialog(
                    "Delete Subject?",
                    isPresented: $model.isConfirmingDeletion
                ) {
                    Button("Delete", role: .destructive) {
                        model.confirmDeletion(from: repositories)
                    }
                } message: {
                    SubjectDeletionMessage(
                        name: model.summary?.subject.name ?? subject.name,
                        gradeCount: model.summary?.gradeCount ?? 0
                    )
                }
            }
        }
        .sheet(item: $formMode) { mode in
            SubjectFormScreen(mode: mode)
        }
        .sheet(item: $gradeFormMode) { mode in
            GradeFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(id: subject.id, from: repositories)
        }
        .onChange(of: model.wasDeleted) {
            if model.wasDeleted {
                dismiss()
            }
        }
    }

    private func startEditing() {
        guard let subject = model.summary?.subject else { return }
        formMode = .edit(subject)
    }

    private func startAddingGrade() {
        guard let id = model.summary?.subject.id else { return }
        gradeFormMode = .create(subjectId: id)
    }

}
