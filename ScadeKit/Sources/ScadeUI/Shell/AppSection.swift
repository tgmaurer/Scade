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

    var id: Self { self }

    /// **Settings is not one of these, on any platform.**
    ///
    /// On macOS it's a window of its own, opened from the app menu or with
    /// ⌘, — where every Mac app keeps it, and where the system will look for
    /// it whether or not the app agrees. A sidebar row for it was a fifth
    /// permanent slot spent on the screen visited least, and it swapped the
    /// whole detail column for a form.
    ///
    /// Everywhere else it's a button on Home, for the same reason a tab would
    /// be wrong (SPEC-POLISH §2.2). iOS has no menu bar to put it in.
    ///
    /// SPEC §4's "Settings in the sidebar" is superseded by the platform
    /// convention; see SPEC-POLISH §2.2.

    var title: LocalizedStringKey { LocalizedStringKey(name) }

    /// The same word as `title`, as a plain `String`.
    ///
    /// Both forms come off one list so they can't drift.
    var name: String {
        switch self {
        case .home: "Home"
        case .educations: "Educations"
        case .subjects: "Subjects"
        case .grades: "Grades"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .educations: "graduationcap"
        case .subjects: "books.vertical"
        case .grades: "list.number"
        }
    }
}
