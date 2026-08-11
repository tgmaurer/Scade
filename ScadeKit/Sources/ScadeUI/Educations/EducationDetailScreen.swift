import ScadeKit
import SwiftUI

/// One education in full, with its subjects (SPEC §4).
struct EducationDetailScreen: View {
    let education: Education

    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model = EducationDetailModel()
    @State private var formMode: EducationFormMode?
    @State private var subjectFormMode: SubjectFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            if let summary = model.summary {
                EducationSummarySection(summary: summary, average: model.average)

                Section("Subjects") {
                    if summary.subjects.isEmpty {
                        Text("No subjects yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summary.subjects) { subjectGrades in
                            NavigationLink(value: subjectGrades.subject) {
                                EducationSubjectRowView(
                                    subjectGrades: subjectGrades,
                                    totalSemesters: summary.education.semesters,
                                    average: GradeCalculator.subjectAverage(of: subjectGrades)
                                )
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.Education.detail)
        .navigationTitle(model.summary?.education.name ?? education.name)
        .toolbar {
            ToolbarItem {
                // §4: creating from here pre-selects and locks this
                // education. Unavailable once the education is completed.
                Button("New Subject", systemImage: "plus", action: startAddingSubject)
                    .disabled(model.summary?.education.completed ?? true)
            }

            ToolbarItem {
                Button("Edit", systemImage: "pencil", action: startEditing)
            }

            ToolbarItem {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.isConfirmingDeletion = true
                }
                .confirmationDialog(
                    "Delete Education?",
                    isPresented: $model.isConfirmingDeletion
                ) {
                    Button("Delete", role: .destructive) {
                        model.confirmDeletion(from: repositories)
                    }
                } message: {
                    EducationDeletionMessage(
                        name: model.summary?.education.name ?? education.name,
                        subjectCount: model.summary?.subjectCount ?? 0
                    )
                }
            }
        }
        .sheet(item: $formMode) { mode in
            EducationFormScreen(mode: mode)
        }
        .sheet(item: $subjectFormMode) { mode in
            SubjectFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(id: education.id, from: repositories)
        }
        .onChange(of: model.wasDeleted) {
            if model.wasDeleted {
                dismiss()
            }
        }
    }

    private func startEditing() {
        guard let education = model.summary?.education else { return }
        formMode = .edit(education)
    }

    private func startAddingSubject() {
        guard let id = model.summary?.education.id else { return }
        subjectFormMode = .create(educationId: id)
    }

}

#Preview {
    NavigationStack {
        EducationDetailScreen(education: PreviewData.education())
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
