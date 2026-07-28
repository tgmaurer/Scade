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

            AboutSection()
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
            model.prepareExport(from: repositories)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
