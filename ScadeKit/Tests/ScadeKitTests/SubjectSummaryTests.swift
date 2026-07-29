import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("SubjectRepository — whole-tree reads")
struct SubjectSummaryTests {
    let database: AppDatabase
    let educations: EducationRepository
    let subjects: SubjectRepository
    let grades: GradeRepository
    let educationId: Int64

    init() throws {
        database = try .inMemory()
        educations = EducationRepository(database: database)
        subjects = SubjectRepository(database: database)
        grades = GradeRepository(database: database)

        let education = try educations.create(Fixture.education(name: "Informatik", semesters: 6))
        educationId = try #require(education.id)
    }

    @Test("Returns an empty list when there are no subjects")
    func emptyDatabase() throws {
        #expect(try subjects.allSummaries().isEmpty)
    }

    @Test("Lists subjects newest-created first")
    func ordersSubjects() throws {
        try subjects.create(Fixture.subject(educationId: educationId, name: "First"))
        try subjects.create(Fixture.subject(educationId: educationId, name: "Second"))

        #expect(try subjects.allSummaries().map(\.subject.name) == ["Second", "First"])
    }

    @Test("Attaches the parent education to every subject")
    func attachesEducations() throws {
        let other = try educations.create(Fixture.education(name: "Mathematik"))
        let otherId = try #require(other.id)

        try subjects.create(Fixture.subject(educationId: educationId, name: "Analysis"))
        try subjects.create(Fixture.subject(educationId: otherId, name: "Algebra"))

        let summaries = try subjects.allSummaries()

        #expect(summaries.map(\.subject.name) == ["Algebra", "Analysis"])
        #expect(summaries.map(\.education.name) == ["Mathematik", "Informatik"])
    }

    @Test("Attaches each subject's own grades, newest-first")
    func attachesGrades() throws {
        let analysis = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Analysis")
        )
        let algebra = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Algebra")
        )
        let analysisId = try #require(analysis.id)

        try grades.create(Fixture.grade(subjectId: analysisId, value: 4.0, date: .iso("2025-01-01")))
        try grades.create(Fixture.grade(subjectId: analysisId, value: 6.0, date: .iso("2025-06-01")))
        try grades.create(Fixture.grade(subjectId: try #require(algebra.id), value: 5.0))

        let summaries = try subjects.allSummaries()
        let analysisSummary = try #require(summaries.first { $0.subject.name == "Analysis" })

        #expect(analysisSummary.grades.map(\.value) == [6.0, 4.0])
        #expect(analysisSummary.gradeCount == 2)
        try expectApproximately(GradeCalculator.subjectAverage(of: analysisSummary.grades), 5.0)
    }

    @Test("Keeps a subject with no grades, with no average")
    func keepsUngradedSubjects() throws {
        try subjects.create(Fixture.subject(educationId: educationId, name: "Ungraded"))

        let summary = try #require(try subjects.allSummaries().first)

        #expect(summary.gradeCount == 0)
        #expect(GradeCalculator.subjectAverage(of: summary.grades) == nil)
    }

    @Test("Fetches a single subject's tree")
    func fetchesSingleSummary() throws {
        let subject = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Analysis", weight: 1.5)
        )
        let subjectId = try #require(subject.id)
        try grades.create(Fixture.grade(subjectId: subjectId, value: 5.0))

        let summary = try #require(try subjects.summary(id: subjectId))

        #expect(summary.subject.name == "Analysis")
        #expect(summary.education.name == "Informatik")
        #expect(summary.gradeCount == 1)
        #expect(summary.subjectGrades.subject.weight == 1.5)
    }

    @Test("Returns nothing for a subject that isn't there")
    func fetchesNothingForMissingSubject() throws {
        #expect(try subjects.summary(id: 999) == nil)
    }

    @Test("Searches a subject summary by its own name and its education's")
    func searchesSummaries() throws {
        try subjects.create(Fixture.subject(educationId: educationId, name: "Analysis"))

        let summaries = try subjects.allSummaries()

        #expect(summaries.matching(searchQuery: "analys").count == 1)
        #expect(summaries.matching(searchQuery: "Informatik").count == 1)
        #expect(summaries.matching(searchQuery: "Algebra").isEmpty)
    }
}

@Suite("GradeRepository — single list item")
struct GradeListItemTests {
    let database: AppDatabase
    let grades: GradeRepository
    let subjectId: Int64

    init() throws {
        database = try .inMemory()
        grades = GradeRepository(database: database)

        let educations = EducationRepository(database: database)
        let subjects = SubjectRepository(database: database)
        let education = try educations.create(Fixture.education(name: "Informatik"))
        let subject = try subjects.create(
            Fixture.subject(educationId: try #require(education.id), name: "Analysis")
        )
        subjectId = try #require(subject.id)
    }

    @Test("Fetches a grade with both of its parents")
    func fetchesListItem() throws {
        let grade = try grades.create(Fixture.grade(subjectId: subjectId, value: 5.25))
        let id = try #require(grade.id)

        let item = try #require(try grades.listItem(id: id))

        #expect(item.grade.value == 5.25)
        #expect(item.subject.name == "Analysis")
        #expect(item.education.name == "Informatik")
    }

    @Test("Returns nothing for a grade that isn't there")
    func fetchesNothingForMissingGrade() throws {
        #expect(try grades.listItem(id: 999) == nil)
    }
}
