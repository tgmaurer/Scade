import Foundation

/// A subject alongside the education it belongs to.
///
/// The subjects list (SPEC §4) shows the parent education's name,
/// institution and completion state, and §3.5 searches the parent's name, so
/// both records are fetched together rather than resolved per row.
public struct SubjectListItem: Hashable, Sendable, Identifiable {
    public var subject: Subject
    public var education: Education

    public var id: Int64? { subject.id }

    public init(subject: Subject, education: Education) {
        self.subject = subject
        self.education = education
    }
}
