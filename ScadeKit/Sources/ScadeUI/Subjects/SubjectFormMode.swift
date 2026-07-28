import ScadeKit
import SwiftUI

/// Whether the subject form is creating or editing, and what it starts from.
///
/// The create case carries the prefill §4 asks for: opened from an education,
/// that education is chosen and locked, and the semester comes from whatever
/// filter was active.
enum SubjectFormMode: Identifiable, Hashable {
    case create(educationId: Int64? = nil, semester: Int? = nil)
    case edit(Subject)

    var id: Int64 {
        switch self {
        case .create: 0
        case .edit(let subject): subject.id ?? 0
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .create: "New Subject"
        case .edit: "Edit Subject"
        }
    }

    var isEditing: Bool {
        switch self {
        case .create: false
        case .edit: true
        }
    }

    /// True when the education was chosen for the user and shouldn't move.
    var locksEducation: Bool {
        switch self {
        case .create(let educationId, _): educationId != nil
        case .edit: false
        }
    }
}
