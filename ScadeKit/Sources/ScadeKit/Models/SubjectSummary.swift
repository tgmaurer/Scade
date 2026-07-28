import Foundation

/// A subject with its education and every one of its grades.
///
/// The subjects list shows the parent education alongside a computed average
/// (SPEC §4), so all three levels are fetched together — the same batching
/// `EducationSummary` does, for the same reason.
public struct SubjectSummary: Identifiable, Hashable, Sendable {
    public var subject: Subject
    public var education: Education
    /// Newest-first, per §3.6.
    public var grades: [Grade]

    public var id: Int64? { subject.id }

    public init(subject: Subject, education: Education, grades: [Grade]) {
        self.subject = subject
        self.education = education
        self.grades = grades
    }

    public var gradeCount: Int { grades.count }

    /// The pairing the education rollup consumes, for callers that already
    /// hold a summary.
    public var subjectGrades: SubjectGrades {
        SubjectGrades(subject: subject, grades: grades)
    }
}
