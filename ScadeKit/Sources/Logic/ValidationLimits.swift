import Foundation

/// Field-length limits from SPEC §3.4, in one place so the forms and the
/// validators can't disagree about them.
public enum ValidationLimits {
    public static let maximumNameLength = 255
    public static let maximumDescriptionLength = 2500
    public static let minimumSemesters = 1
}
