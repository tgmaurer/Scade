import Foundation
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The one place grades are deliberately not newest-first.
///
/// Worth its own test because it contradicts the canonical order in SPEC §3.6
/// and reads, at a glance, like the bug that section exists to prevent. The
/// exception is written down there; this stops it being "fixed" by someone
/// who has only read the rule.
@MainActor
struct HomeSubjectTests {
    private func date(month: Int) throws -> CalendarDate {
        try #require(CalendarDate(year: 2026, month: month, day: 1))
    }

    /// As the repository hands them over: newest-first (date desc, id desc).
    private func canonicallyOrdered() throws -> SubjectGrades {
        SubjectGrades(
            subject: Subject(educationId: 1, name: "Module 404", semester: 2),
            grades: [
                Grade(id: 3, subjectId: 1, value: 6.0, date: try date(month: 3)),
                Grade(id: 2, subjectId: 1, value: 5.0, date: try date(month: 2)),
                Grade(id: 1, subjectId: 1, value: 4.0, date: try date(month: 1)),
            ]
        )
    }

    @Test func laysGradesOutOldestFirst() throws {
        let item = HomeSubject(try canonicallyOrdered())

        #expect(item.grades.map(\.id) == [1, 2, 3])
    }

    /// The average is a weighted mean, so reordering must not move it — and
    /// if it ever did, that would be the bug, not the order.
    @Test func reorderingDoesNotChangeTheAverage() throws {
        let source = try canonicallyOrdered()

        let item = HomeSubject(source)

        #expect(item.average == GradeCalculator.subjectAverage(of: source.grades))
    }
}
