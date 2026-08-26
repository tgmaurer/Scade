import ScadeKit
import SwiftUI

/// One subject in full, with its grades (SPEC §4).
struct SubjectDetailScreen: View {
    let subject: Subject

    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigate) private var navigate

    @State private var model = SubjectDetailModel()
    @State private var formMode: SubjectFormMode?
    @State private var gradeFormMode: GradeFormMode?

    var body: some View {
        @Bindable var model = model

        DetailScroll {
            if let summary = model.summary {
                subjectSummarySection(summary: summary, average: model.average)

                grades(of: summary)
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
        // The menu bar's version of the three buttons above, plus the
        // way up to the education this belongs to (SPEC-POLISH §1.2).
        .focusedSceneValue(\.newRecord, newGradeAction)
        .focusedSceneValue(\.editRecord, ScreenAction("Edit Subject", perform: startEditing))
        .focusedSceneValue(\.deleteRecord, ScreenAction("Delete Subject…") { model.isConfirmingDeletion = true })
        .focusedSceneValue(\.openParent, openEducationAction)
        .task {
            await model.observe(id: subject.id, from: repositories)
        }
        .onChange(of: model.wasDeleted) {
            if model.wasDeleted {
                dismiss()
            }
        }
    }

    /// The subject's grades, as one card of many rows.
    ///
    /// A list, like the education detail's subjects and for the same reason:
    /// this is one record's contents, read down a column while the header
    /// above it stays in view. The top-level Grades screen is a grid, which
    /// §2.5 records as an override taken on that screen alone — it does not
    /// follow a grade wherever a grade appears.
    ///
    /// The rows show no parent: the screen around them already says which
    /// subject and which education this is, which is what `showsContext`
    /// exists to drop.
    @ViewBuilder
    private func grades(of summary: SubjectSummary) -> some View {
        DetailSection(title: "Grades") {
            if summary.grades.isEmpty {
                DetailSectionText {
                    Text("No grades yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(summary.grades.enumerated(), id: \.element.id) { index, grade in
                    DetailCardRow(
                        position: CardRowPosition(index: index, count: summary.grades.count)
                    ) {
                        CardRowLink(destination: grade) {
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

    private func startEditing() {
        guard let subject = model.summary?.subject else { return }
        formMode = .edit(subject)
    }

    private func startAddingGrade() {
        guard let id = model.summary?.subject.id else { return }
        gradeFormMode = .create(subjectId: id)
    }

    /// `nil` on a completed subject, matching the toolbar button §4 disables
    /// there — the menu shows the command greyed rather than dropping it.
    private var newGradeAction: ScreenAction? {
        guard model.summary?.subject.completed == false else { return nil }
        return ScreenAction("New Grade", perform: startAddingGrade)
    }

    /// `⌘↑`, the way Finder's Enclosing Folder works: the record this one
    /// sits inside.
    private var openEducationAction: ScreenAction? {
        guard let education = model.summary?.education else { return nil }
        return ScreenAction("Open Education") { navigate(education) }
    }
}
