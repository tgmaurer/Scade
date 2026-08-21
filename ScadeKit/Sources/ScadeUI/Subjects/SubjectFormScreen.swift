import ScadeKit
import SwiftUI

/// Create or edit a subject (SPEC §4).
struct SubjectFormScreen: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model: SubjectFormModel

    init(mode: SubjectFormMode) {
        _model = State(initialValue: SubjectFormModel(mode: mode))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    FormTextField(
                        title: "Name",
                        text: $model.name,
                        identifier: AccessibilityID.Subject.name
                    )
                    FieldErrorLabel(model.message(for: .name))

                    if model.mode.locksEducation {
                        LabeledContent("Education", value: model.selectedEducation?.name ?? "—")
                    } else {
                        Picker("Education", selection: $model.educationId) {
                            ForEach(model.educations) { education in
                                Text(education.name).tag(education.id)
                            }
                        }
                    }
                }

                Section {
                    LabeledContent("Semester") {
                        TextField("Semester", value: $model.semester, format: .number)
                            .numberPadKeyboard()
                            .multilineTextAlignment(.trailing)
                            .labelsHidden()
                            .accessibilityIdentifier(AccessibilityID.Subject.semester)
                    }
                    FieldErrorLabel(model.message(for: .semester))

                    if let education = model.selectedEducation {
                        Text("This education runs for ^[\(education.semesters) semester](inflect: true).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    WeightField(title: "Weight", percent: $model.weightPercent)
                    FieldErrorLabel(model.message(for: .weight))
                }

                if model.mode.isEditing {
                    Section {
                        Toggle("Completed", isOn: $model.completed)
                    }
                }

                Section("Description") {
                    TextField("Description", text: $model.details, axis: .vertical)
                        .lineLimit(3...)
                        .labelsHidden()
                    FieldErrorLabel(model.message(for: .description))
                }
            }
            .formStyle(.grouped)
            .navigationTitle(model.mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                        .accessibilityIdentifier(AccessibilityID.Form.cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .accessibilityIdentifier(AccessibilityID.Form.save)
                }
            }
            .alert("Couldn't save", isPresented: $model.isShowingError) {
            } message: {
                Text(model.errorMessage ?? "")
            }
            .onAppear {
                model.load(from: repositories)
            }
        }
    }

    private func save() {
        if model.save(to: repositories) {
            dismiss()
        }
    }
}

#Preview("Create") {
    SubjectFormScreen(mode: .create())
        .environment(\.repositories, PreviewData.seededRepositories)
}
