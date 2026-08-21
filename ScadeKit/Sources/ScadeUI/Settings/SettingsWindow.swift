#if os(macOS)
import ScadeKit
import SwiftUI

/// Settings as its own window (SPEC-POLISH §2.2).
///
/// Every Mac app keeps Settings in the app menu and on ⌘, — the shortcut is
/// wired by the system to the `Settings` scene whether or not the app has
/// anything to put behind it, so an app that answers it with a sidebar row
/// instead is answering a question nobody asked and leaving the standard one
/// dead.
///
/// Public because the scene lives in the App target and everything else about
/// the UI doesn't. It takes the repositories the same way `RootView` does:
/// handed in, never reached for.
///
/// The width is fixed and the height follows the form. A settings window is
/// read top to bottom and has nothing to lay out differently when it's wider,
/// so a resize handle here is a gesture with no outcome — the same reason the
/// sidebar's width is fixed.
public struct SettingsWindow: View {
    @AppStorage("appTheme") private var theme: AppTheme = .system

    private let repositories: Repositories

    public init(repositories: Repositories) {
        self.repositories = repositories
    }

    public var body: some View {
        SettingsScreen()
            .frame(width: ScadeDesign.settingsWindowWidth)
            .frame(minHeight: ScadeDesign.settingsWindowHeight)
            .environment(\.repositories, repositories)
            // Its own window, so it doesn't inherit what `RootView` sets:
            // without this, choosing Dark leaves Settings light.
            .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    SettingsWindow(repositories: .inMemory)
}
#endif
