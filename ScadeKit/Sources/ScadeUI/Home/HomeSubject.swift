import ScadeKit
import SwiftUI

/// One subject on the dashboard, with its average already worked out.
struct HomeSubject: Identifiable, Hashable, Sendable {
    let subject: Subject
    let grades: [Grade]
    let average: Double?

    var id: Int64? { subject.id }

    init(_ subjectGrades: SubjectGrades) {
        subject = subjectGrades.subject
        grades = subjectGrades.grades
        average = GradeCalculator.subjectAverage(of: subjectGrades.grades)
    }
}
