import ScadeKit
import SwiftUI

extension CompletionFilter {
    /// Kept out of ScadeKit so the domain layer doesn't import SwiftUI just
    /// to name a picker option.
    var title: LocalizedStringKey {
        switch self {
        case .all: "All"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        }
    }
}
