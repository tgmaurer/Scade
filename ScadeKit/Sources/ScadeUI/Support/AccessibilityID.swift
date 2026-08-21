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
    /// A shell section — a tab on iPhone, a sidebar row everywhere else.
    static func section(_ section: AppSection) -> String {
        "section.\(section.rawValue)"
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

    enum Home {
        /// The dashboard's education picker.
        static let educationMenu = "home.educationMenu"
    }

    enum Education {
        static let new = "education.new"

        /// Marks the detail screen itself, for the same reason `Subject`'s
        /// does: the education's name is on the list the push started from
        /// too, so its presence proves nothing about navigation.
        static let detail = "education.detail"

        static let name = "education.form.name"
        static let institution = "education.form.institution"
        static let semesters = "education.form.semesters"
    }

    enum Subject {
        static let new = "subject.new"
        static let name = "subject.form.name"
        static let semester = "subject.form.semester"

        /// Marks the detail screen itself, so a test can tell that a push
        /// actually happened rather than that the name is on screen — which
        /// it also is on the screen the push started from.
        static let detail = "subject.detail"

        static let edit = "subject.edit"
    }

    enum Grade {
        static let new = "grade.new"
        static let value = "grade.form.value"
        static let detail = "grade.detail"
    }

    enum Settings {
        /// The way in where there's no menu bar to keep Settings in —
        /// everywhere but macOS. See `AppSection`.
        static let open = "settings.open"
        static let deleteAll = "settings.deleteAll"
        static let confirmDeleteAll = "settings.deleteAll.confirm"
    }
}
