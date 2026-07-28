import ScadeKit
import SwiftUI

/// One line of the educations list, with its average already worked out.
///
/// The average is computed once when the list loads rather than inside
/// `body`, which SwiftUI may call far more often than the data changes.
struct EducationRow: Identifiable, Hashable, Sendable {
    let education: Education
    let average: Double?
    let subjectCount: Int

    var id: Int64? { education.id }

    init(_ summary: EducationSummary) {
        education = summary.education
        average = GradeCalculator.educationAverage(of: summary.subjects)
        subjectCount = summary.subjectCount
    }
}

extension EducationRow: Searchable {
    /// Defers to the domain layer, so "what gets searched" is defined in one
    /// place (§3.5) rather than per screen.
    var searchableFields: [String?] { education.searchableFields }
}
