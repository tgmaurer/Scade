import ScadeKit
import SwiftUI

#if os(macOS)
import AppKit
#endif

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

            #if os(macOS)
            Section {
                LabeledContent("Folder") {
                    HStack {
                        Text(model.backupFolder?.lastPathComponent ?? "Not chosen")
                            .foregroundStyle(model.backupFolder == nil ? .secondary : .primary)

                        Button("Choose…", action: model.chooseBackupFolder)
                    }
                }
                .padding(.top, ScadeDesign.formButtonRowTopPadding)

                Button("Back Up Now") {
                    model.backUpNow(from: repositories)
                }
                .disabled(model.backupFolder == nil)

                if let date = model.lastBackup {
                    LabeledContent("Last Backup") {
                        HStack {
                            Text(date, format: .dateTime.day().month().year().hour().minute())

                            if let folder = model.lastBackupFolder {
                                Button("Show in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([folder])
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("Writes a dated folder holding a copy of your database, an overview sheet and its three tables as CSV. iCloud Drive is a good place for it — a backup on this Mac alone is lost with this Mac.")
            }
            #else
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
            #endif

            Section {
                Button("Delete All Data", role: .destructive) {
                    model.isShowingResetConfirmation = true
                }
                .disabled(model.educationCount == 0)
                .accessibilityIdentifier(AccessibilityID.Settings.deleteAll)
                // Attached to the button, not the form: the dialog animates
                // out of whatever it's attached to.
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
            } header: {
                Text("Data")
            } footer: {
                Text("Removes every education, subject and grade from this device. Back up first if you might want any of it back.")
            }

            AboutSection()
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
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
