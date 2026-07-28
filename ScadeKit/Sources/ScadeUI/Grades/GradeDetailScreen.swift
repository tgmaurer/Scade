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

        List {
            if let item = model.item {
                Section {
                    LabeledContent("Grade") {
                        GradeValueLabel(item.grade.value)
                    }

                    LabeledContent("Weight") {
                        WeightLabel(item.grade.weight)
                    }

                    LabeledContent("Date") {
                        Text(
                            item.grade.date.startOfDay(),
                            format: .dateTime.day().month().year()
                        )
                    }
                }

                Section("Subject") {
                    LabeledContent("Name", value: item.subject.name)

                    LabeledContent("Semester") {
                        Text("\(item.subject.semester.formatted(.number.grouping(.never))) of \(item.education.semesters.formatted(.number.grouping(.never)))")
                    }

                    LabeledContent("Status") {
                        CompletionBadge(isCompleted: item.subject.completed)
                    }
                }

                Section("Education") {
                    LabeledContent("Name", value: item.education.name)

                    if let institution = item.education.institution, institution.isEmpty == false {
                        LabeledContent("Institution", value: institution)
                    }

                    LabeledContent("Status") {
                        CompletionBadge(isCompleted: item.education.completed)
                    }
                }

                if let details = item.grade.description, details.isEmpty == false {
                    Section("Description") {
                        Text(details)
                    }
                }
            }
        }
        .navigationTitle("Grade")
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
        .sheet(item: $formMode, onDismiss: reload) { mode in
            GradeFormScreen(mode: mode)
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
        guard let grade = model.item?.grade else { return }
        formMode = .edit(grade)
    }

    private func reload() {
        model.load(id: grade.id, from: repositories)
    }
}
