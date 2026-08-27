import ScadeKit
import SwiftUI

/// Create or edit an education (SPEC §4).
struct EducationFormScreen: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model: EducationFormModel

    init(mode: EducationFormMode) {
        _model = State(initialValue: EducationFormModel(mode: mode))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    FormTextField(
                        title: "Name",
                        text: $model.name,
                        identifier: AccessibilityID.Education.name
                    )
                    FieldErrorLabel(model.message(for: .name))

                    FormTextField(
                        title: "Institution",
                        text: $model.institution,
                        identifier: AccessibilityID.Education.institution
                    )
                }

                Section {
                    DatePicker(
                        "Start Date",
                        selection: $model.startDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "End Date",
                        selection: $model.endDate,
                        displayedComponents: .date
                    )
                    FieldErrorLabel(model.message(for: .endDate))

                    IntegerField(
                        title: "Semesters",
                        value: $model.semesters,
                        identifier: AccessibilityID.Education.semesters
                    )
                    FieldErrorLabel(model.message(for: .semesters))
                }

                // §3.4: completion is reachable only by editing — an
                // education is always born in progress.
                if model.mode.isEditing {
                    Section {
                        Toggle("Completed", isOn: $model.completed)
                    }
                }

                Section("Description") {
                    FormTextEditor(title: "Description", text: $model.details)
                    FieldErrorLabel(model.message(for: .description))
                }
            }
            .formStyle(.grouped)
            .saveShortcut(save)
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
        }
    }

    private func save() {
        if model.save(to: repositories) {
            dismiss()
        }
    }
}

#Preview("Create") {
    EducationFormScreen(mode: .create)
        .environment(\.repositories, PreviewData.seededRepositories)
}

#Preview("Edit") {
    EducationFormScreen(mode: .edit(PreviewData.education()))
        .environment(\.repositories, PreviewData.seededRepositories)
}
