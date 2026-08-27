import Foundation
import ScadeKit

/// Sample records for `#Preview` blocks.
///
/// Compiled in every configuration, not just Debug. It was `#if DEBUG` once,
/// on the reasonable-sounding grounds that sample data shouldn't ship — but
/// a `#Preview` body is compiled in Release too, and the 52 of them in this
/// target are not guarded, so a Release build failed with 57 errors the
/// first time one was attempted. Guarding this one file and leaving the
/// previews unguarded is the shape that doesn't work; the alternative is
/// fifty hand-written `#if DEBUG` fences around blocks that exist to be
/// read. A few hundred lines of sample structs in a binary that is never
/// distributed is the cheaper side of that trade.
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

    static func subjectRow(
        id: Int64 = 1,
        name: String = "Analysis",
        semester: Int = 3,
        weight: Double = 1.0,
        completed: Bool = false,
        grades: [Grade] = [Grade(subjectId: 1, value: 5.5, date: .today())]
    ) -> SubjectRow {
        var subject = Subject(educationId: 1, name: name, semester: semester, weight: weight)
        subject.id = id
        subject.completed = completed

        return SubjectRow(
            SubjectSummary(subject: subject, education: education(), grades: grades)
        )
    }

    static func gradeItem(
        id: Int64 = 1,
        value: Double = 5.5,
        weight: Double = 1.0,
        details: String? = "Schlussprüfung",
        subjectName: String = "Analysis"
    ) -> GradeListItem {
        let grade = Grade(
            id: id,
            subjectId: 1,
            value: value,
            weight: weight,
            description: details,
            date: .today()
        )

        var subject = Subject(educationId: 1, name: subjectName, semester: 2)
        subject.id = 1

        return GradeListItem(grade: grade, subject: subject, education: education())
    }

    static func educationRow(
        id: Int64 = 1,
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
            EducationSummary(education: education(id: id, completed: completed), subjects: subjects)
        )
    }

    static func homeSubject(
        name: String = "Analysis I",
        semester: Int = 1,
        failing: Bool = false
    ) -> HomeSubject {
        HomeSubject(
            SubjectGrades(
                subject: Subject(educationId: 1, name: name, semester: semester),
                grades: [Grade(subjectId: 1, value: failing ? 3.5 : 5.25, date: .today())]
            )
        )
    }

    /// An in-memory store with a little data in it, so previews of the list
    /// screens aren't all empty states.
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
