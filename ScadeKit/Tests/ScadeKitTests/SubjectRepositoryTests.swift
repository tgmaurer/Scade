import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("SubjectRepository")
struct SubjectRepositoryTests {
    let database: AppDatabase
    let repository: SubjectRepository
    let educations: EducationRepository
    let grades: GradeRepository
    let educationId: Int64

    init() throws {
        database = try .inMemory()
        repository = SubjectRepository(database: database)
        educations = EducationRepository(database: database)
        grades = GradeRepository(database: database)

        let education = try educations.create(Fixture.education(name: "Informatik", semesters: 6))
        educationId = try #require(education.id)
    }

    // MARK: - Creating

    @Test("Assigns an id on insert and reads the record back")
    func createAssignsIdentifier() throws {
        let created = try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 2, weight: 1.5)
        )
        let id = try #require(created.id)

        #expect(created.name == "Analysis")
        #expect(created.semester == 2)
        #expect(created.weight == 1.5)
        #expect(try repository.find(id: id) == created)
    }

    @Test("Forces a new subject to be in progress")
    func createIgnoresCompletion() throws {
        let created = try repository.create(
            Fixture.subject(educationId: educationId, completed: true)
        )

        #expect(created.completed == false)
    }

    // MARK: - Uniqueness

    /// The old app enforced this in app code only, leaving a window between
    /// the check and the insert. It's an index now, so the repository just
    /// translates the violation.
    @Test("Rejects a duplicate name in the same education and semester")
    func rejectsDuplicate() throws {
        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
        )

        #expect(throws: RepositoryError.duplicateSubject) {
            try repository.create(
                Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
            )
        }
    }

    @Test("Treats a name that differs only in case as a duplicate")
    func rejectsCaseInsensitiveDuplicate() throws {
        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
        )

        #expect(throws: RepositoryError.duplicateSubject) {
            try repository.create(
                Fixture.subject(educationId: educationId, name: "ANALYSIS", semester: 1)
            )
        }
    }

    @Test("Allows the same name in a different semester")
    func allowsSameNameInOtherSemester() throws {
        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
        )
        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 2)
        )

        #expect(try repository.all().count == 2)
    }

    @Test("Allows the same name in a different education")
    func allowsSameNameInOtherEducation() throws {
        let other = try educations.create(Fixture.education(name: "Mathematik"))
        let otherId = try #require(other.id)

        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
        )
        try repository.create(Fixture.subject(educationId: otherId, name: "Analysis", semester: 1))

        #expect(try repository.all().count == 2)
    }

    @Test("Rejects an edit that would collide with another subject")
    func rejectsDuplicateOnUpdate() throws {
        try repository.create(
            Fixture.subject(educationId: educationId, name: "Analysis", semester: 1)
        )
        var second = try repository.create(
            Fixture.subject(educationId: educationId, name: "Algebra", semester: 1)
        )

        second.name = "Analysis"

        #expect(throws: RepositoryError.duplicateSubject) {
            try repository.update(second)
        }
    }

    // MARK: - Reading

    /// §3.6: semester descending, then name ascending, then id descending —
    /// on every screen, not just Home.
    @Test("Lists an education's subjects in canonical order")
    func listsInCanonicalOrder() throws {
        try repository.create(Fixture.subject(educationId: educationId, name: "Beta", semester: 1))
        try repository.create(Fixture.subject(educationId: educationId, name: "Alpha", semester: 2))
        try repository.create(Fixture.subject(educationId: educationId, name: "Gamma", semester: 2))
        try repository.create(Fixture.subject(educationId: educationId, name: "Alpha", semester: 1))

        let names = try repository.inEducation(educationId).map { "\($0.semester)-\($0.name)" }

        #expect(names == ["2-Alpha", "2-Gamma", "1-Alpha", "1-Beta"])
    }

    @Test("Restricts to a single semester for the Home filter")
    func listsBySemester() throws {
        try repository.create(Fixture.subject(educationId: educationId, name: "Alpha", semester: 1))
        try repository.create(Fixture.subject(educationId: educationId, name: "Beta", semester: 2))
        try repository.create(Fixture.subject(educationId: educationId, name: "Gamma", semester: 2))

        let names = try repository.inEducation(educationId, semester: 2).map(\.name)

        #expect(names == ["Beta", "Gamma"])
    }

    @Test("Lists all subjects newest-created first")
    func listsAllNewestFirst() throws {
        try repository.create(Fixture.subject(educationId: educationId, name: "First"))
        try repository.create(Fixture.subject(educationId: educationId, name: "Second"))

        #expect(try repository.all().map(\.name) == ["Second", "First"])
    }

    @Test("Lists only in-progress subjects for the grade form's picker")
    func listsInProgressOnly() throws {
        let finished = try repository.create(
            Fixture.subject(educationId: educationId, name: "Finished")
        )
        try repository.create(Fixture.subject(educationId: educationId, name: "Ongoing"))

        var completed = finished
        completed.completed = true
        try repository.update(completed)

        #expect(try repository.inProgress().map(\.name) == ["Ongoing"])
    }

    @Test("Pairs each subject with its education for the list screen")
    func listsWithParentEducation() throws {
        let other = try educations.create(Fixture.education(name: "Mathematik"))
        let otherId = try #require(other.id)

        try repository.create(Fixture.subject(educationId: educationId, name: "Analysis"))
        try repository.create(Fixture.subject(educationId: otherId, name: "Algebra"))

        let items = try repository.allListItems()

        #expect(items.map(\.subject.name) == ["Algebra", "Analysis"])
        #expect(items.map(\.education.name) == ["Mathematik", "Informatik"])
    }

    @Test("Counts an education's subjects for the delete confirmation")
    func countsWithinEducation() throws {
        let other = try educations.create(Fixture.education(name: "Mathematik"))
        let otherId = try #require(other.id)

        try repository.create(Fixture.subject(educationId: educationId, name: "Analysis"))
        try repository.create(Fixture.subject(educationId: educationId, name: "Algebra"))
        try repository.create(Fixture.subject(educationId: otherId, name: "Analysis"))

        #expect(try repository.count(inEducation: educationId) == 2)
        #expect(try repository.count(inEducation: otherId) == 1)
    }

    // MARK: - Reading for averages

    @Test("Attaches every grade to its subject")
    func fetchesSubjectWithGrades() throws {
        let subject = try repository.create(Fixture.subject(educationId: educationId))
        let subjectId = try #require(subject.id)
        try grades.create(Fixture.grade(subjectId: subjectId, value: 4.0))
        try grades.create(Fixture.grade(subjectId: subjectId, value: 6.0))

        let fetched = try #require(try repository.subjectWithGrades(id: subjectId))

        #expect(fetched.grades.count == 2)
        try expectApproximately(GradeCalculator.subjectAverage(of: fetched), 5.0)
    }

    @Test("Returns nothing for a subject that isn't there")
    func fetchesNothingForMissingSubject() throws {
        #expect(try repository.subjectWithGrades(id: 999) == nil)
    }

    /// The set the education rollup runs on. Subjects without grades stay in
    /// the result with an empty array — dropping them here would hide them
    /// from the screen, and §3.2 only excludes them from the *average*.
    @Test("Includes ungraded subjects with an empty grade list")
    func includesUngradedSubjects() throws {
        let graded = try repository.create(
            Fixture.subject(educationId: educationId, name: "Graded", semester: 2)
        )
        try repository.create(Fixture.subject(educationId: educationId, name: "Ungraded", semester: 1))
        try grades.create(Fixture.grade(subjectId: try #require(graded.id), value: 5.0))

        let fetched = try repository.subjectsWithGrades(educationId: educationId)

        #expect(fetched.map(\.subject.name) == ["Graded", "Ungraded"])
        #expect(fetched.map(\.grades.count) == [1, 0])
        try expectApproximately(GradeCalculator.educationAverage(of: fetched), 5.0)
    }

    @Test("Keeps each subject's grades with that subject")
    func groupsGradesBySubject() throws {
        let first = try repository.create(
            Fixture.subject(educationId: educationId, name: "Alpha", semester: 2)
        )
        let second = try repository.create(
            Fixture.subject(educationId: educationId, name: "Beta", semester: 1)
        )
        try grades.create(Fixture.grade(subjectId: try #require(first.id), value: 6.0))
        try grades.create(Fixture.grade(subjectId: try #require(first.id), value: 6.0))
        try grades.create(Fixture.grade(subjectId: try #require(second.id), value: 4.0))

        let fetched = try repository.subjectsWithGrades(educationId: educationId)

        #expect(fetched.map(\.subject.name) == ["Alpha", "Beta"])
        #expect(fetched.map { $0.grades.map(\.value) } == [[6.0, 6.0], [4.0]])
    }

    @Test("Orders each subject's grades newest-first")
    func ordersAttachedGradesNewestFirst() throws {
        let subject = try repository.create(Fixture.subject(educationId: educationId))
        let subjectId = try #require(subject.id)
        try grades.create(Fixture.grade(subjectId: subjectId, value: 4.0, date: .iso("2025-01-01")))
        try grades.create(Fixture.grade(subjectId: subjectId, value: 6.0, date: .iso("2025-06-01")))
        try grades.create(Fixture.grade(subjectId: subjectId, value: 5.0, date: .iso("2025-03-01")))

        let fetched = try #require(try repository.subjectWithGrades(id: subjectId))

        #expect(fetched.grades.map(\.value) == [6.0, 5.0, 4.0])
    }

    @Test("Restricts the fetched set to one semester")
    func fetchesBySemester() throws {
        try repository.create(Fixture.subject(educationId: educationId, name: "Alpha", semester: 1))
        try repository.create(Fixture.subject(educationId: educationId, name: "Beta", semester: 2))

        let fetched = try repository.subjectsWithGrades(educationId: educationId, semester: 2)

        #expect(fetched.map(\.subject.name) == ["Beta"])
    }

    @Test("Returns an empty set for an education with no subjects")
    func fetchesEmptySet() throws {
        #expect(try repository.subjectsWithGrades(educationId: educationId).isEmpty)
        #expect(GradeCalculator.educationAverage(of: []) == nil)
    }

    // MARK: - Updating and deleting

    @Test("Writes every field back and refreshes updatedAt")
    func updateWritesFields() throws {
        var subject = try repository.create(Fixture.subject(educationId: educationId))
        let id = try #require(subject.id)

        subject.name = "Lineare Algebra"
        subject.semester = 3
        subject.weight = 2.5
        subject.completed = true
        subject.updatedAt = Date(timeIntervalSince1970: 0)
        let updated = try repository.update(subject)

        let stored = try #require(try repository.find(id: id))
        #expect(stored.name == "Lineare Algebra")
        #expect(stored.semester == 3)
        #expect(stored.weight == 2.5)
        #expect(stored.completed)
        #expect(abs(updated.updatedAt.timeIntervalSinceNow) < 60)
    }

    @Test("Refuses to update a record with no id or no row")
    func updateFailures() throws {
        #expect(throws: RepositoryError.missingIdentifier) {
            try repository.update(Fixture.subject(educationId: educationId))
        }

        var missing = Fixture.subject(educationId: educationId)
        missing.id = 999
        #expect(throws: RepositoryError.notFound) {
            try repository.update(missing)
        }
    }

    @Test("Deletes the subject and its grades")
    func deleteCascades() throws {
        let subject = try repository.create(Fixture.subject(educationId: educationId))
        let subjectId = try #require(subject.id)
        try grades.create(Fixture.grade(subjectId: subjectId))

        #expect(try repository.delete(id: subjectId))
        #expect(try repository.find(id: subjectId) == nil)
        #expect(try grades.all().isEmpty)
        #expect(try repository.delete(id: subjectId) == false)
    }
}
