import ScadeKit
import SwiftUI

extension ValidationError {
    /// What to show under the offending field.
    ///
    /// The wording lives here rather than in ScadeKit so the domain layer
    /// stays free of presentation — the rule and the sentence explaining it
    /// are different concerns.
    var message: String {
        switch self {
        case .nameRequired:
            "Enter a name."
        case .nameTooLong(let maximum):
            "Keep the name to \(maximum) characters or fewer."
        case .descriptionTooLong(let maximum):
            "Keep the description to \(maximum) characters or fewer."
        case .semestersOutOfRange(let minimum):
            "An education needs at least \(minimum) semester."
        case .endDateBeforeStartDate:
            "The end date can't come before the start date."
        case .semesterOutOfRange(let minimum, let maximum):
            "Choose a semester between \(minimum) and \(maximum)."
        case .weightNotPositive:
            "The weight has to be greater than zero."
        case .valueOutOfRange(let minimum, let maximum):
            "Grades run from \(minimum.formatted()) to \(maximum.formatted())."
        case .dateOutsideEducationRange(let start, let end):
            "Choose a date between \(start.iso8601String) and \(end.iso8601String)."
        }
    }
}

extension Collection<ValidationError> {
    /// The first problem with `field`, if there is one.
    func message(for field: ValidationField) -> String? {
        first { $0.field == field }?.message
    }
}
