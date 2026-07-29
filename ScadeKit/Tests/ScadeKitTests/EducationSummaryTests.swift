import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("EducationRepository — whole-tree reads")
struct EducationSummaryTests {
    let database: AppDatabase
    let educations: EducationRepository
    let subjects: SubjectRepository
    let grades: GradeRepository

    init() throws {
        database = try .inMemory()
        educations = EducationRepository(database: database)
        subjects = SubjectRepository(database: database)
        grades = GradeRepository(database: database)
    }

    @Test("Returns an empty list when there are no educations")
    func emptyDatabase() throws {
        #expect(try educations.allSummaries().isEmpty)
    }

    @Test("Returns an education with no subjects attached")
    func educationWithoutSubjects() throws {
        try educations.create(Fixture.education(name: "Informatik"))

        let summaries = try educations.allSummaries()

        #expect(summaries.count == 1)
        #expect(summaries[0].subjects.isEmpty)
        #expect(summaries[0].subjectCount == 0)
        #expect(summaries[0].gradeCount == 0)
        #expect(GradeCalculator.educationAverage(of: summaries[0].subjects) == nil)
    }

    @Test("Lists educations newest-created first")
    func ordersEducations() throws {
        try educations.create(Fixture.education(name: "First"))
        try educations.create(Fixture.education(name: "Second"))

        #expect(try educations.allSummaries().map(\.education.name) == ["Second", "First"])
    }

    /// The reason this method exists: every row's average comes from one
    /// batch, not from a query per education.
    @Test("Attaches each education's own subjects and grades")
    func groupsAcrossEducations() throws {
        let first = try educations.create(Fixture.education(name: "Informatik"))
        let second = try educations.create(Fixture.education(name: "Mathematik"))
        let firstId = try #require(first.id)
        let secondId = try #require(second.id)

        let analysis = try subjects.create(
            Fixture.subject(educationId: firstId, name: "Analysis", weight: 3.0)
        )
        let algebra = try subjects.create(
            Fixture.subject(educationId: firstId, name: "Algebra", weight: 1.0)
        )
        let statistik = try subjects.create(
            Fixture.subject(educationId: secondId, name: "Statistik")
        )

        try grades.create(Fixture.grade(subjectId: try #require(analysis.id), value: 6.0))
        try grades.create(Fixture.grade(subjectId: try #require(algebra.id), value: 4.0))
        try grades.create(Fixture.grade(subjectId: try #require(statistik.id), value: 5.0))

        let summaries = try educations.allSummaries()
        let informatik = try #require(summaries.first { $0.education.name == "Informatik" })
        let mathematik = try #require(summaries.first { $0.education.name == "Mathematik" })

        #expect(informatik.subjectCount == 2)
        #expect(informatik.gradeCount == 2)
        #expect(mathematik.subjectCount == 1)

        // (6.0 × 3 + 4.0 × 1) / 4 = 5.5
        try expectApproximately(GradeCalculator.educationAverage(of: informatik.subjects), 5.5)
        try expectApproximately(GradeCalculator.educationAverage(of: mathematik.subjects), 5.0)
    }

    @Test("Keeps subjects in canonical order within each education")
    func ordersSubjectsCanonically() throws {
        let education = try educations.create(Fixture.education(semesters: 6))
        let educationId = try #require(education.id)

        try subjects.create(Fixture.subject(educationId: educationId, name: "Beta", semester: 1))
        try subjects.create(Fixture.subject(educationId: educationId, name: "Alpha", semester: 2))
        try subjects.create(Fixture.subject(educationId: educationId, name: "Gamma", semester: 2))

        let summary = try #require(try educations.allSummaries().first)
        let ordered = summary.subjects.map { "\($0.subject.semester)-\($0.subject.name)" }

        #expect(ordered == ["2-Alpha", "2-Gamma", "1-Beta"])
    }

    @Test("Keeps each subject's grades newest-first")
    func ordersGradesNewestFirst() throws {
        let education = try educations.create(Fixture.education())
        let educationId = try #require(education.id)
        let subject = try subjects.create(Fixture.subject(educationId: educationId))
        let subjectId = try #require(subject.id)

        try grades.create(Fixture.grade(subjectId: subjectId, value: 4.0, date: .iso("2025-01-01")))
        try grades.create(Fixture.grade(subjectId: subjectId, value: 6.0, date: .iso("2025-06-01")))

        let summary = try #require(try educations.allSummaries().first)

        #expect(summary.subjects[0].grades.map(\.value) == [6.0, 4.0])
    }

    @Test("Fetches a single education's tree")
    func fetchesSingleSummary() throws {
        let education = try educations.create(Fixture.education(name: "Informatik"))
        let educationId = try #require(education.id)
        let subject = try subjects.create(Fixture.subject(educationId: educationId))
        try grades.create(Fixture.grade(subjectId: try #require(subject.id), value: 5.0))

        let summary = try #require(try educations.summary(id: educationId))

        #expect(summary.education.name == "Informatik")
        #expect(summary.subjectCount == 1)
        #expect(summary.gradeCount == 1)
        try expectApproximately(GradeCalculator.educationAverage(of: summary.subjects), 5.0)
    }

    @Test("Returns nothing for an education that isn't there")
    func fetchesNothingForMissingEducation() throws {
        #expect(try educations.summary(id: 999) == nil)
    }

    /// §3.2 again, this time through the repository: a subject nobody has
    /// been marked in yet must not drag the education's average down.
    @Test("Leaves ungraded subjects out of the average but not out of the list")
    func keepsUngradedSubjects() throws {
        let education = try educations.create(Fixture.education(semesters: 6))
        let educationId = try #require(education.id)

        let graded = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Graded", semester: 2)
        )
        try subjects.create(Fixture.subject(educationId: educationId, name: "Ungraded", semester: 1))
        try grades.create(Fixture.grade(subjectId: try #require(graded.id), value: 5.0))

        let summary = try #require(try educations.summary(id: educationId))

        #expect(summary.subjectCount == 2)
        try expectApproximately(GradeCalculator.educationAverage(of: summary.subjects), 5.0)
    }
}
