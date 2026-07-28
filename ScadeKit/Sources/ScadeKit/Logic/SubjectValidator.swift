import Foundation

/// The subject rules from SPEC §3.4.
public enum SubjectValidator {

    /// Returns every broken rule; an empty array means the subject is valid.
    ///
    /// The parent education is passed in explicitly rather than looked up:
    /// the caller already has it, and a validator that quietly queries the
    /// database would be doing work its signature doesn't admit to.
    ///
    /// Uniqueness of `(education, name, semester)` is *not* checked here — it
    /// is enforced by `idx_subjects_unique` and surfaces as
    /// `RepositoryError.duplicateSubject` on save. Checking it here as well
    /// would just reopen the check-then-write race the index closed.
    public static func validate(_ subject: Subject, in education: Education) -> [ValidationError] {
        var errors: [ValidationError] = []

        errors += FieldRules.name(subject.name)
        errors += FieldRules.description(subject.description)
        errors += FieldRules.weight(subject.weight)

        // Rejected, not clamped: the semester must fit inside the education
        // the subject belongs to.
        let maximum = max(education.semesters, ValidationLimits.minimumSemesters)
        if (ValidationLimits.minimumSemesters...maximum).contains(subject.semester) == false {
            errors.append(
                .semesterOutOfRange(minimum: ValidationLimits.minimumSemesters, maximum: maximum)
            )
        }

        return errors
    }
}
