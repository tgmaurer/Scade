import Foundation
import GRDB
import Testing

@testable import ScadeKit

// MARK: - Dates

extension CalendarDate {
    /// Builds a date from a literal in tests.
    ///
    /// Traps on a malformed literal rather than returning an optional: a bad
    /// date string here is a typo in the test, not a runtime condition worth
    /// handling.
    static func iso(_ text: String) -> CalendarDate {
        guard let date = CalendarDate(iso8601: text) else {
            fatalError("'\(text)' is not a yyyy-MM-dd date")
        }
        return date
    }
}

// MARK: - Fixtures

/// Valid-by-default records, so each test only spells out the field it cares
/// about.
enum Fixture {
    static func education(
        name: String = "Informatik",
        description: String? = nil,
        semesters: Int = 6,
        startDate: CalendarDate = .iso("2024-09-01"),
        endDate: CalendarDate = .iso("2027-08-31"),
        institution: String? = "ETH Zürich",
        completed: Bool = false
    ) -> Education {
        Education(
            name: name,
            description: description,
            semesters: semesters,
            startDate: startDate,
            endDate: endDate,
            institution: institution,
            completed: completed
        )
    }

    static func subject(
        educationId: Int64,
        name: String = "Analysis",
        description: String? = nil,
        semester: Int = 1,
        weight: Double = 1.0,
        completed: Bool = false
    ) -> Subject {
        Subject(
            educationId: educationId,
            name: name,
            description: description,
            semester: semester,
            weight: weight,
            completed: completed
        )
    }

    /// A grade defaults to *having* a description, unlike the other two
    /// fixtures: §3.4 requires one, so `nil` here would make every "this
    /// grade is valid" assertion fail for a reason it wasn't testing.
    static func grade(
        subjectId: Int64,
        value: Double = 5.0,
        weight: Double = 1.0,
        description: String? = "Schlussprüfung",
        date: CalendarDate = .iso("2025-01-15")
    ) -> Grade {
        Grade(
            subjectId: subjectId,
            value: value,
            weight: weight,
            description: description,
            date: date
        )
    }

    /// A subject/grade pair built in memory, for calculator tests that have no
    /// need of a database.
    static func subjectGrades(
        subjectWeight: Double,
        gradeValues: [Double],
        gradeWeights: [Double]? = nil
    ) -> SubjectGrades {
        let weights = gradeWeights ?? Array(repeating: 1.0, count: gradeValues.count)
        let grades = zip(gradeValues, weights).map { value, weight in
            Grade(subjectId: 1, value: value, weight: weight, date: .iso("2025-01-15"))
        }

        return SubjectGrades(
            subject: Subject(educationId: 1, name: "Subject", semester: 1, weight: subjectWeight),
            grades: grades
        )
    }
}

// MARK: - Assertions

/// Compares floating-point results within a tolerance.
///
/// The averages are sums of binary floating-point products, so exact equality
/// would be testing IEEE 754 rather than the formula.
func expectApproximately(
    _ actual: Double?,
    _ expected: Double,
    tolerance: Double = 1e-9,
    sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let actual = try #require(actual, "expected a value, got nil", sourceLocation: sourceLocation)
    #expect(
        abs(actual - expected) <= tolerance,
        "\(actual) is not within \(tolerance) of \(expected)",
        sourceLocation: sourceLocation
    )
}
