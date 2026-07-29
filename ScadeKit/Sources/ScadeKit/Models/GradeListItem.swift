import Foundation

/// A grade alongside its subject and education.
///
/// The grades list (SPEC §4) shows both parents, and §3.5 searches the parent
/// names, so all three records are fetched together rather than resolved per
/// row.
public struct GradeListItem: Hashable, Sendable, Identifiable {
    public var grade: Grade
    public var subject: Subject
    public var education: Education

    public var id: Int64? { grade.id }

    public init(grade: Grade, subject: Subject, education: Education) {
        self.grade = grade
        self.subject = subject
        self.education = education
    }
}
