import Foundation

/// The education rules from SPEC §3.4.
public enum EducationValidator {

    /// Returns every broken rule; an empty array means the education is valid.
    public static func validate(_ education: Education) -> [ValidationError] {
        var errors: [ValidationError] = []

        errors += FieldRules.name(education.name)
        errors += FieldRules.description(education.description)

        if education.semesters < ValidationLimits.minimumSemesters {
            errors.append(.semestersOutOfRange(minimum: ValidationLimits.minimumSemesters))
        }

        // Also enforced by `CHECK (endDate >= startDate)`; checked here so the
        // user gets a field error instead of a failed write.
        if education.endDate < education.startDate {
            errors.append(.endDateBeforeStartDate)
        }

        return errors
    }
}
