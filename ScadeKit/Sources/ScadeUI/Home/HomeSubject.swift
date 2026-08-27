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
        // Oldest-first here alone (SPEC §3.6). The row lays these out as a
        // horizontal run, which reads as a timeline — left to right is
        // earlier to later — while every list of grades stays newest-first.
        //
        // Reversing rather than re-sorting: the canonical order is total
        // (date desc, then id desc), so its reverse is exactly date asc then
        // id asc. Sorting again here would be a second copy of an order the
        // repository already owns.
        grades = subjectGrades.grades.reversed()
        average = GradeCalculator.subjectAverage(of: subjectGrades.grades)
    }
}
