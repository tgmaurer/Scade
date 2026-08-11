import ScadeKit
import SwiftUI

/// The whole app, minus the `App` shell that hosts it.
///
/// Everything the views need arrives through `repositories`; the App target
/// only has to open the database and hand it over.
///
/// The shell itself is per-platform, because the right answer genuinely
/// differs: a fixed-width sidebar on macOS, a tab bar on iOS (SPEC-POLISH
/// §2.2). One `TabView(.sidebarAdaptable)` did serve both from a single
/// declaration, but it gave up control macOS needs — chiefly the sidebar's
/// width, which is system-managed and not constrainable there.
///
/// Only the shell forks, and each one owns which section is showing: a
/// `TabView` selects in a non-optional and a `List` in an optional, so a
/// shared binding would have to be adapted for one of them. Every screen below
/// is shared.
public struct RootView: View {
    @AppStorage("appTheme") private var theme: AppTheme = .system

    private let repositories: Repositories

    public init(repositories: Repositories) {
        self.repositories = repositories
    }

    public var body: some View {
        Group {
            #if os(macOS)
            SidebarShell()
            #else
            TabShell()
            #endif
        }
        .windowSizeFloor()
        .environment(\.repositories, repositories)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView(repositories: .inMemory)
}
