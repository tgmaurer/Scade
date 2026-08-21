import Foundation

/// The grade rules from SPEC §3.4.
public enum GradeValidator {

    /// Returns every broken rule; an empty array means the grade is valid.
    ///
    /// The education is passed in because the date range a grade must fall
    /// inside belongs to the education, not the subject.
    ///
    /// The subject requirement from §3.4 is structural rather than checked
    /// here: `Grade.subjectId` is non-optional and backed by a foreign key,
    /// so a grade without a subject can't be built in the first place.
    public static func validate(_ grade: Grade, in education: Education) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Required here and nowhere else — see `FieldRules.description`.
        errors += FieldRules.description(grade.description, isRequired: true)
        errors += FieldRules.weight(grade.weight)

        // 1–6, full stop. The old app's form carried a `Min=0` bound that
        // never matched its own `[Range(1, 6)]` annotation; it was dead code,
        // not a second opinion.
        if GradingScale.contains(grade.value) == false || grade.value.isFinite == false {
            errors.append(
                .valueOutOfRange(
                    minimum: GradingScale.range.lowerBound,
                    maximum: GradingScale.range.upperBound
                )
            )
        }

        // Rejected, not clamped.
        if let range = education.dateRange {
            if range.contains(grade.date) == false {
                errors.append(
                    .dateOutsideEducationRange(start: education.startDate, end: education.endDate)
                )
            }
        } else {
            // The education's own dates are inverted, so no grade date can be
            // valid against it. That's the education's error to fix, but the
            // grade can't be saved either.
            errors.append(
                .dateOutsideEducationRange(start: education.startDate, end: education.endDate)
            )
        }

        return errors
    }
}
