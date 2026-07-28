import Foundation

/// A subject together with *all* of its grades, fetched in one go.
///
/// SPEC §3.2 calls out a bug the old app shipped: an average computed from a
/// lazily-loaded navigation collection that had never been populated, which
/// silently produced 0. This type exists so averages are only ever computed
/// from an explicitly, fully-fetched set — there is no lazy edge to fall off.
public struct SubjectGrades: Hashable, Sendable, Identifiable {
    public var subject: Subject
    public var grades: [Grade]

    public var id: Int64? { subject.id }

    public init(subject: Subject, grades: [Grade]) {
        self.subject = subject
        self.grades = grades
    }
}
