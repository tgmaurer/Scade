import ScadeKit
import SwiftUI

/// One education in full, with its subjects (SPEC §4).
struct EducationDetailScreen: View {
    let education: Education

    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model = EducationDetailModel()
    @State private var formMode: EducationFormMode?

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
        .navigationTitle(model.summary?.education.name ?? education.name)
        .toolbar {
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
        .sheet(item: $formMode, onDismiss: reload) { mode in
            EducationFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear(perform: reload)
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

    private func reload() {
        model.load(id: education.id, from: repositories)
    }
}

#Preview {
    NavigationStack {
        EducationDetailScreen(education: PreviewData.education())
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
