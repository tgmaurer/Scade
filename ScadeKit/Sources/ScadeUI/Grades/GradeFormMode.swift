import ScadeKit
import SwiftUI

/// Whether the grade form is creating or editing, and what it starts from.
enum GradeFormMode: Identifiable, Hashable {
    case create(subjectId: Int64? = nil)
    case edit(Grade)

    var id: Int64 {
        switch self {
        case .create: 0
        case .edit(let grade): grade.id ?? 0
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .create: "New Grade"
        case .edit: "Edit Grade"
        }
    }

    var isEditing: Bool {
        switch self {
        case .create: false
        case .edit: true
        }
    }
}
