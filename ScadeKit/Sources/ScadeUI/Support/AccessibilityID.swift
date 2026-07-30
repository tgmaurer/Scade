import SwiftUI

/// Stable handles for the elements `ScadeUITests` drives.
///
/// The tests target these rather than visible labels, because the polish
/// phase is expected to reword buttons and retitle fields — a flow test
/// should only fail when the *flow* breaks, not when a caption changes.
///
/// The UI test target can't import this module, so it mirrors these strings
/// in its own `ID` enum. Change one, change the other.
enum AccessibilityID {
    static func sidebarSection(_ section: SidebarSection) -> String {
        "sidebar.\(section.rawValue)"
    }

    /// Shared by all three forms — only one is ever presented at a time.
    enum Form {
        static let save = "form.save"
        static let cancel = "form.cancel"

        /// Every inline validation message carries this, so a test can count
        /// them. Deliberately not per-field: the field a message belongs to
        /// is a detail the validator unit tests already pin down.
        static let error = "form.error"
    }

    enum Education {
        static let new = "education.new"
        static let name = "education.form.name"
        static let institution = "education.form.institution"
        static let semesters = "education.form.semesters"
    }

    enum Subject {
        static let new = "subject.new"
        static let name = "subject.form.name"
        static let semester = "subject.form.semester"
    }

    enum Grade {
        static let new = "grade.new"
        static let value = "grade.form.value"
    }

    enum Settings {
        static let deleteAll = "settings.deleteAll"
        static let confirmDeleteAll = "settings.deleteAll.confirm"
    }
}
