import ScadeKit
import SwiftUI

/// Create or edit a grade (SPEC §4).
struct GradeFormScreen: View {
    @Environment(\.repositories) private var repositories
    @Environment(\.dismiss) private var dismiss

    @State private var model: GradeFormModel

    init(mode: GradeFormMode) {
        _model = State(initialValue: GradeFormModel(mode: mode))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    LabeledContent("Grade") {
                        TextField("Grade", value: $model.value, format: .number)
                            .decimalPadKeyboard()
                            .multilineTextAlignment(.trailing)
                            .labelsHidden()
                            .accessibilityIdentifier(AccessibilityID.Grade.value)
                    }
                    FieldErrorLabel(model.message(for: .value))

                    Picker("Subject", selection: $model.subjectId) {
                        ForEach(model.subjects) { item in
                            Text("\(item.subject.name) · \(item.education.name)")
                                .tag(item.subject.id)
                        }
                    }
                }

                Section {
                    WeightField(title: "Weight", percent: $model.weightPercent)
                    FieldErrorLabel(model.message(for: .weight))

                    LabeledContent("Quick Picks") {
                        WeightPresetMenu(percent: $model.weightPercent)
                    }
                }

                Section {
                    DatePicker("Date", selection: $model.date, displayedComponents: .date)
                    FieldErrorLabel(model.message(for: .date))

                    if let education = model.selectedSubject?.education {
                        Text("This education runs from \(education.startDate.iso8601String) to \(education.endDate.iso8601String).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Required, unlike an education's or a subject's: those
                // have a name and a grade does not, so this is the only
                // thing that can say what the number was for (§3.4).
                Section("Description") {
                    TextField("Description", text: $model.details, axis: .vertical)
                        .lineLimit(3...)
                        .labelsHidden()
                        .accessibilityIdentifier(AccessibilityID.Grade.description)
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
    GradeFormScreen(mode: .create())
        .environment(\.repositories, PreviewData.seededRepositories)
}
