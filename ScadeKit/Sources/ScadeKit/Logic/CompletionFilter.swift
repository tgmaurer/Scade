import Foundation

/// The completion-state filter control from SPEC §3.5.
///
/// Deliberately a separate control from the search field: the old app encoded
/// this as `(ip)`/`(c)` suffixes typed into the search text, which meant the
/// only way to discover the feature was to already know about it.
public enum CompletionFilter: String, CaseIterable, Hashable, Sendable, Identifiable {
    case all
    case inProgress
    case completed

    public var id: Self { self }

    public func matches(completed isCompleted: Bool) -> Bool {
        switch self {
        case .all: true
        case .inProgress: isCompleted == false
        case .completed: isCompleted
        }
    }
}
