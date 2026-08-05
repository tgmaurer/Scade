import SwiftUI

/// Settings, presented modally.
///
/// The route on iPhone, where Settings has no section of its own
/// (SPEC-POLISH §2.2). A sheet rather than a push because it's a detour from
/// the dashboard, not somewhere you navigate *to* — and it keeps Home's back
/// stack meaning one thing.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsScreen()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: dismiss.callAsFunction)
                    }
                }
        }
    }
}

#Preview {
    SettingsSheet()
        .environment(\.repositories, PreviewData.seededRepositories)
}
