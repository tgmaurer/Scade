import ScadeKit
import SwiftUI

/// Settings (SPEC §4): appearance, backup, and what the app is.
struct SettingsScreen: View {
    @Environment(\.repositories) private var repositories
    @AppStorage("appTheme") private var theme: AppTheme = .system
    @State private var model = SettingsModel()

    var body: some View {
        @Bindable var model = model

        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    ForEach(AppTheme.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }

            Section {
                if let url = model.exportURL {
                    ShareLink("Export Database", item: url)
                } else {
                    Text("Preparing export…")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("Shares a copy of your database. Keep it somewhere safe — it holds every education, subject and grade.")
            }

            Section {
                Button("Delete All Data", role: .destructive) {
                    model.isShowingResetConfirmation = true
                }
                .disabled(model.educationCount == 0)
                .accessibilityIdentifier(AccessibilityID.Settings.deleteAll)
            } header: {
                Text("Data")
            } footer: {
                Text("Removes every education, subject and grade from this device. Export a backup first if you might want any of it back.")
            }

            AboutSection()
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $model.isShowingResetConfirmation
        ) {
            Button("Delete Everything", role: .destructive) {
                model.deleteAllData(from: repositories)
            }
            .accessibilityIdentifier(AccessibilityID.Settings.confirmDeleteAll)
        } message: {
            Text("^[\(model.educationCount) education](inflect: true) and everything in them will be deleted. This can't be undone.")
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
            model.load(from: repositories)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
