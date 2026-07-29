import ScadeKit
import SwiftUI

/// One line of the subjects list, with its average already worked out.
struct SubjectRow: Identifiable, Hashable, Sendable {
    let subject: Subject
    let education: Education
    let average: Double?
    let gradeCount: Int

    var id: Int64? { subject.id }

    init(_ summary: SubjectSummary) {
        subject = summary.subject
        education = summary.education
        average = GradeCalculator.subjectAverage(of: summary.grades)
        gradeCount = summary.gradeCount
    }
}

extension SubjectRow: Searchable {
    var searchableFields: [String?] {
        [subject.name, subject.description, education.name]
    }
}
