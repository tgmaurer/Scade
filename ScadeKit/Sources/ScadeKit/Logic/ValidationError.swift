import Foundation

/// A single broken rule from SPEC §3.4.
///
/// Validators return these rather than throwing on the first one, so a form
/// can show everything that's wrong at once instead of one problem per save.
public enum ValidationError: Error, Hashable, Sendable {
    case nameRequired
    case nameTooLong(maximum: Int)
    case descriptionTooLong(maximum: Int)

    /// An education's total semester count is below 1.
    case semestersOutOfRange(minimum: Int)

    case endDateBeforeStartDate

    /// A subject's semester is outside `1...education.semesters`.
    ///
    /// The old app quietly clamped this and raised a toast. Rejecting it
    /// instead means the user sees the number they typed and the reason it
    /// won't do, rather than watching their input change by itself.
    case semesterOutOfRange(minimum: Int, maximum: Int)

    /// A weight below zero, or not a number at all. Zero itself is allowed —
    /// see `FieldRules.weight`.
    case weightNegative

    /// A grade value outside the 1–6 Swiss scale.
    case valueOutOfRange(minimum: Double, maximum: Double)

    /// A grade dated outside its education's start/end range. Rejected rather
    /// than clamped, for the same reason as `semesterOutOfRange`.
    case dateOutsideEducationRange(start: CalendarDate, end: CalendarDate)

    /// Where this error should be shown.
    public var field: ValidationField {
        switch self {
        case .nameRequired, .nameTooLong: .name
        case .descriptionTooLong: .description
        case .semestersOutOfRange: .semesters
        case .endDateBeforeStartDate: .endDate
        case .semesterOutOfRange: .semester
        case .weightNegative: .weight
        case .valueOutOfRange: .value
        case .dateOutsideEducationRange: .date
        }
    }
}
