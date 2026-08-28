import Foundation

/// The rules that appear on more than one form, written once.
///
/// Name, description and weight are validated identically wherever they turn
/// up in SPEC §3.4, so the three entity validators share these rather than
/// each carrying their own copy of the limits.
enum FieldRules {

    /// Required, and at most `ValidationLimits.maximumNameLength` characters.
    ///
    /// Whitespace-only counts as empty, and the length is measured after
    /// trimming — otherwise trailing spaces could push an otherwise fine name
    /// over the limit.
    static func name(_ value: String) -> [ValidationError] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return [.nameRequired]
        }
        if trimmed.count > ValidationLimits.maximumNameLength {
            return [.nameTooLong(maximum: ValidationLimits.maximumNameLength)]
        }
        return []
    }

    /// Optional, and at most `ValidationLimits.maximumDescriptionLength`
    /// characters.
    ///
    /// Optional on a grade too, which was briefly not the case — see
    /// [SPEC-BACKLOG](../../../docs/SPEC-BACKLOG.md) for why it was made
    /// required and why that was undone.
    static func description(_ value: String?) -> [ValidationError] {
        guard let value else { return [] }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > ValidationLimits.maximumDescriptionLength else { return [] }

        return [.descriptionTooLong(maximum: ValidationLimits.maximumDescriptionLength)]
    }

    /// Zero or more — matching the `CHECK (weight >= 0)` constraint on both
    /// `Subjects` and `Grades`.
    ///
    /// Zero is allowed and means "doesn't count": a subject you sit but that
    /// carries no marks, a practice paper you want on the record without it
    /// moving the average. It is a real weight, not a missing one, so it is
    /// entered and stored like any other rather than needing a flag of its
    /// own. What that does to an average is `GradeCalculator`'s business.
    static func weight(_ value: Double) -> [ValidationError] {
        value >= 0 && value.isFinite ? [] : [.weightNegative]
    }
}
