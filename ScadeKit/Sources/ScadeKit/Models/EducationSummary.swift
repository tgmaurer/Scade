import Foundation

/// An education with every subject and grade beneath it, fetched in one go.
///
/// This is what the educations list and detail screens run on: the list shows
/// a computed average per education (SPEC §4), and computing that one
/// education at a time would mean a query per row. Fetching the whole tree up
/// front keeps it to a fixed number of queries and — as in `SubjectGrades` —
/// guarantees the averages are taken from a fully materialised set.
public struct EducationSummary: Identifiable, Hashable, Sendable {
    public var education: Education
    /// In the canonical subject order from §3.6.
    public var subjects: [SubjectGrades]

    public var id: Int64? { education.id }

    public init(education: Education, subjects: [SubjectGrades]) {
        self.education = education
        self.subjects = subjects
    }

    public var subjectCount: Int { subjects.count }

    public var gradeCount: Int {
        subjects.reduce(0) { $0 + $1.grades.count }
    }
}
