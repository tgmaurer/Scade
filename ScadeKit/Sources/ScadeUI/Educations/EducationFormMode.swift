import ScadeKit
import SwiftUI

/// Whether the education form is creating or editing.
///
/// §3.4 makes this more than cosmetic: completion is settable only when
/// editing, because educations are always born in progress.
enum EducationFormMode: Identifiable, Hashable {
    case create
    case edit(Education)

    var id: Int64 {
        switch self {
        case .create: 0
        case .edit(let education): education.id ?? 0
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .create: "New Education"
        case .edit: "Edit Education"
        }
    }

    var isEditing: Bool {
        switch self {
        case .create: false
        case .edit: true
        }
    }
}
