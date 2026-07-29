#if DEBUG
import Foundation
import ScadeKit

/// Sample records for `#Preview` blocks.
///
/// Debug-only, so none of it reaches a shipping build.
enum PreviewData {
    static func education(
        id: Int64 = 1,
        name: String = "Angewandte Informatik",
        institution: String? = "ETH Zürich",
        semesters: Int = 6,
        completed: Bool = false
    ) -> Education {
        var education = Education(
            name: name,
            description: "Bachelorstudium in angewandter Informatik.",
            semesters: semesters,
            startDate: .today(),
            endDate: .today().adding(years: 3),
            institution: institution,
            completed: completed
        )
        education.id = id
        return education
    }

    static func educationRow(
        average: Double?,
        subjectCount: Int = 4,
        completed: Bool = false
    ) -> EducationRow {
        let subjects = (0..<subjectCount).map { index in
            SubjectGrades(
                subject: Subject(educationId: 1, name: "Subject \(index)", semester: 1),
                grades: average.map { [Grade(subjectId: 1, value: $0, date: .today())] } ?? []
            )
        }

        return EducationRow(
            EducationSummary(education: education(completed: completed), subjects: subjects)
        )
    }

    /// An in-memory store with a little data in it, so previews of the list
    /// screens aren't all empty states.
    @MainActor
    static let seededRepositories: Repositories = {
        let repositories = Repositories.inMemory
        try? seed(into: repositories)
        return repositories
    }()

    private static func seed(into repositories: Repositories) throws {
        let informatik = try repositories.educations.create(
            Education(
                name: "Angewandte Informatik",
                description: "Bachelorstudium in angewandter Informatik.",
                semesters: 6,
                startDate: .iso("2024-09-01") ?? .today(),
                endDate: .iso("2027-08-31") ?? .today(),
                institution: "ETH Zürich"
            )
        )
        let paedagogik = try repositories.educations.create(
            Education(
                name: "Pädagogik",
                semesters: 4,
                startDate: .iso("2021-09-01") ?? .today(),
                endDate: .iso("2023-08-31") ?? .today(),
                institution: "Universität Basel"
            )
        )

        guard let informatikId = informatik.id, let paedagogikId = paedagogik.id else { return }

        let analysis = try repositories.subjects.create(
            Subject(educationId: informatikId, name: "Analysis", semester: 1, weight: 1.5)
        )
        let algorithmen = try repositories.subjects.create(
            Subject(educationId: informatikId, name: "Algorithmen", semester: 2)
        )
        try repositories.subjects.create(
            Subject(educationId: paedagogikId, name: "Didaktik", semester: 1)
        )

        if let analysisId = analysis.id {
            try repositories.grades.create(
                Grade(subjectId: analysisId, value: 5.5, date: .iso("2025-01-20") ?? .today())
            )
            try repositories.grades.create(
                Grade(
                    subjectId: analysisId, value: 3.75, weight: 0.5,
                    date: .iso("2025-03-10") ?? .today()
                )
            )
        }
        if let algorithmenId = algorithmen.id {
            try repositories.grades.create(
                Grade(subjectId: algorithmenId, value: 6.0, date: .iso("2025-06-02") ?? .today())
            )
        }
    }
}

extension CalendarDate {
    /// Convenience for the sample data above.
    fileprivate static func iso(_ text: String) -> CalendarDate? {
        CalendarDate(iso8601: text)
    }
}
#endif
