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

    /// At most `ValidationLimits.maximumDescriptionLength` characters, and
    /// required where the record has nothing else to call itself.
    ///
    /// `isRequired` is only true for a grade. An education and a subject have
    /// a name, so a description there is genuinely an extra; a grade has no
    /// name field, so this is the only thing that can say what it was for.
    /// Whitespace-only counts as empty, the same rule `name` uses.
    static func description(_ value: String?, isRequired: Bool = false) -> [ValidationError] {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return isRequired ? [.descriptionRequired] : []
        }
        if trimmed.count > ValidationLimits.maximumDescriptionLength {
            return [.descriptionTooLong(maximum: ValidationLimits.maximumDescriptionLength)]
        }
        return []
    }

    /// Strictly positive — matching the `CHECK (weight > 0)` constraint on
    /// both `Subjects` and `Grades`.
    static func weight(_ value: Double) -> [ValidationError] {
        value > 0 && value.isFinite ? [] : [.weightNotPositive]
    }
}
