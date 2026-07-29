import Foundation

/// The form field a validation error belongs against.
///
/// SPEC §3.4 asks for inline field errors instead of the old app's
/// silent-clamp-and-toast, so every error has to know where it should appear.
public enum ValidationField: Hashable, Sendable, CaseIterable {
    case name
    case description
    case institution
    case semesters
    case semester
    case startDate
    case endDate
    case date
    case weight
    case value
}
