import SwiftUI

/// The top-level areas of the app (SPEC §4).
///
/// One `Tab` each. `.sidebarAdaptable` decides how they're presented — a
/// bottom tab bar on iPhone, a sidebar on macOS, a top bar that adapts into a
/// sidebar on iPad — so nothing here has to know which platform it's on
/// (SPEC-POLISH §2.2).
enum AppSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case educations
    case subjects
    case grades
    case settings

    var id: Self { self }

    /// Whether Settings is one of the shell's sections.
    ///
    /// Only where the shell is a real sidebar, which is macOS alone. A tab
    /// slot is permanent real estate and Settings is visited rarely, so
    /// elsewhere it lives behind a button on Home (SPEC-POLISH §2.2), and
    /// SPEC §4's "Settings in the sidebar" is honoured where a sidebar exists.
    ///
    /// iPad was expected to keep it, on the assumption that
    /// `.sidebarAdaptable` would give it a sidebar. It doesn't: iPadOS renders
    /// a top tab bar, and five tabs plus its sidebar toggle don't fit an
    /// 11-inch portrait window — the bar paginates and Settings lands on a
    /// second page, present in the accessibility tree but not reachable by
    /// tapping. `defaultAdaptableTabBarPlacement(.sidebar)` doesn't override
    /// this. Four tabs fit, so four tabs it is.
    static var showsSettingsSection: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .educations: "Educations"
        case .subjects: "Subjects"
        case .grades: "Grades"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .educations: "graduationcap"
        case .subjects: "books.vertical"
        case .grades: "list.number"
        case .settings: "gearshape"
        }
    }
}
