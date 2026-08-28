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

        DetailScroll {
            if let summary = model.summary {
                educationSummarySection(summary: summary, average: model.average)

                subjects(of: summary)
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
                    .help(
                        model.summary?.education.completed ?? true
                            ? "This education is completed. Reopen it to add a subject."
                            : "Add a subject to this education"
                    )
            }

            ToolbarItem {
                Button("Edit", systemImage: "pencil", action: startEditing)
                    .help("Edit this education")
            }

            ToolbarItem {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.isConfirmingDeletion = true
                }
                .help("Delete this education")
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
        // The menu bar's version of the three buttons above
        // (SPEC-POLISH §1.2).
        .focusedSceneValue(\.newRecord, ScreenAction("New Subject", perform: startAddingSubject))
        .focusedSceneValue(\.editRecord, ScreenAction("Edit Education", perform: startEditing))
        .focusedSceneValue(\.deleteRecord, ScreenAction("Delete Education…") { model.isConfirmingDeletion = true })
        .task {
            await model.observe(id: education.id, from: repositories)
        }
        .onChange(of: model.wasDeleted) {
            if model.wasDeleted {
                dismiss()
            }
        }
    }

    /// The education's subjects, as one card of many rows.
    ///
    /// A list and not a grid, unlike the three top-level screens: those are
    /// collections you arrive at to pick from, and this is one record's
    /// contents, read down a column while the header above it stays in view.
    /// §2.5's "one card of many rows versus many cards of one row" — this is
    /// the first kind.
    @ViewBuilder
    private func subjects(of summary: EducationSummary) -> some View {
        DetailSection(title: "Subjects") {
            if summary.subjects.isEmpty {
                DetailSectionText {
                    Text("No subjects yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(summary.subjects.enumerated(), id: \.element.id) { index, subjectGrades in
                    DetailCardRow(
                        position: CardRowPosition(index: index, count: summary.subjects.count)
                    ) {
                        CardRowLink(destination: subjectGrades.subject) {
                            EducationSubjectRowView(
                                subjectGrades: subjectGrades,
                                average: GradeCalculator.subjectAverage(of: subjectGrades)
                            )
                        }
                    }
                }
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
