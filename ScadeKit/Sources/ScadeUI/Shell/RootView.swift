import ScadeKit
import SwiftUI

/// The whole app, minus the `App` shell that hosts it.
///
/// Everything the views need arrives through `repositories`; the App target
/// only has to open the database and hand it over.
///
/// One `TabView` for every platform. `.sidebarAdaptable` resolves it per
/// platform — a bottom tab bar on iPhone, a sidebar on macOS, a top bar that
/// adapts into a sidebar on iPad — so macOS keeps the sidebar SPEC §4
/// describes while iPhone gets a shell it can actually navigate. This replaced
/// a `NavigationSplitView`, which collapsed on iPhone into a stack whose root
/// *was* the sidebar: changing section meant navigating back to a menu
/// (SPEC-POLISH §2.2).
///
/// iPadOS gives a top tab bar with a sidebar toggle rather than a sidebar
/// outright. `defaultAdaptableTabBarPlacement(.sidebar)` was tried and had no
/// observable effect, so it isn't carried — see `AppSection.showsSettingsSection`
/// for what that costs and how it's paid for.
///
/// The identifiers reach the rendered tab on iOS and iPadOS but not the
/// sidebar row on macOS, which AppKit draws from the title alone. `ScadeUITests`
/// matches on the title there; see its `openSection(_:)`.
public struct RootView: View {
    @State private var section: AppSection = .home
    @AppStorage("appTheme") private var theme: AppTheme = .system

    private let repositories: Repositories

    public init(repositories: Repositories) {
        self.repositories = repositories
    }

    public var body: some View {
        TabView(selection: $section) {
            Tab(
                AppSection.home.title,
                systemImage: AppSection.home.systemImage,
                value: .home
            ) {
                SectionStack {
                    HomeScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.home))

            Tab(
                AppSection.educations.title,
                systemImage: AppSection.educations.systemImage,
                value: .educations
            ) {
                SectionStack {
                    EducationListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.educations))

            Tab(
                AppSection.subjects.title,
                systemImage: AppSection.subjects.systemImage,
                value: .subjects
            ) {
                SectionStack {
                    SubjectListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.subjects))

            Tab(
                AppSection.grades.title,
                systemImage: AppSection.grades.systemImage,
                value: .grades
            ) {
                SectionStack {
                    GradeListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.grades))

            // Absent on iPhone, where Home's toolbar carries it instead.
            if AppSection.showsSettingsSection {
                Tab(
                    AppSection.settings.title,
                    systemImage: AppSection.settings.systemImage,
                    value: .settings
                ) {
                    SectionStack {
                        SettingsScreen()
                    }
                }
                .accessibilityIdentifier(AccessibilityID.section(.settings))
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(ScadeDesign.accent)
        .environment(\.repositories, repositories)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView(repositories: .inMemory)
}
