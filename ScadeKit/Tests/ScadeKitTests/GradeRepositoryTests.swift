import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("GradeRepository")
struct GradeRepositoryTests {
    let database: AppDatabase
    let repository: GradeRepository
    let subjects: SubjectRepository
    let educations: EducationRepository
    let educationId: Int64
    let subjectId: Int64

    init() throws {
        database = try .inMemory()
        repository = GradeRepository(database: database)
        subjects = SubjectRepository(database: database)
        educations = EducationRepository(database: database)

        let education = try educations.create(Fixture.education(name: "Informatik"))
        educationId = try #require(education.id)
        let subject = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Analysis")
        )
        subjectId = try #require(subject.id)
    }

    // MARK: - Creating

    @Test("Assigns an id on insert and reads the record back")
    func createAssignsIdentifier() throws {
        let created = try repository.create(
            Fixture.grade(
                subjectId: subjectId,
                value: 5.25,
                weight: 0.625,
                description: "Schlussprüfung",
                date: .iso("2025-06-15")
            )
        )
        let id = try #require(created.id)

        #expect(created.value == 5.25)
        #expect(created.weight == 0.625)
        #expect(created.description == "Schlussprüfung")
        #expect(created.date == .iso("2025-06-15"))
        #expect(try repository.find(id: id) == created)
    }

    @Test("Stamps updatedAt at insert time")
    func createStampsTimestamp() throws {
        var grade = Fixture.grade(subjectId: subjectId)
        grade.updatedAt = Date(timeIntervalSince1970: 0)

        let created = try repository.create(grade)

        #expect(abs(created.updatedAt.timeIntervalSinceNow) < 60)
    }

    @Test("Refuses a value the scale doesn't allow, even without validation")
    func databaseRejectsOutOfScaleValue() {
        #expect(throws: DatabaseError.self) {
            try repository.create(Fixture.grade(subjectId: subjectId, value: 0.0))
        }
    }

    // MARK: - Reading

    @Test("Returns nothing for an id that isn't there")
    func findMissingReturnsNil() throws {
        #expect(try repository.find(id: 999) == nil)
    }

    /// §3.6: newest-first, by date then id — including on Home, which was the
    /// one screen in the old app that listed grades oldest-first.
    @Test("Lists a subject's grades newest-first")
    func listsNewestFirstByDate() throws {
        try repository.create(Fixture.grade(subjectId: subjectId, value: 4.0, date: .iso("2025-01-01")))
        try repository.create(Fixture.grade(subjectId: subjectId, value: 6.0, date: .iso("2025-06-01")))
        try repository.create(Fixture.grade(subjectId: subjectId, value: 5.0, date: .iso("2025-03-01")))

        #expect(try repository.forSubject(subjectId).map(\.value) == [6.0, 5.0, 4.0])
    }

    @Test("Breaks a date tie with the newest grade first")
    func breaksDateTiesByIdentifier() throws {
        let date = CalendarDate.iso("2025-03-01")
        try repository.create(Fixture.grade(subjectId: subjectId, value: 4.0, date: date))
        try repository.create(Fixture.grade(subjectId: subjectId, value: 5.0, date: date))
        try repository.create(Fixture.grade(subjectId: subjectId, value: 6.0, date: date))

        #expect(try repository.forSubject(subjectId).map(\.value) == [6.0, 5.0, 4.0])
    }

    @Test("Lists only the requested subject's grades")
    func scopesToSubject() throws {
        let other = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Algebra")
        )
        let otherId = try #require(other.id)

        try repository.create(Fixture.grade(subjectId: subjectId, value: 4.0))
        try repository.create(Fixture.grade(subjectId: otherId, value: 6.0))

        #expect(try repository.forSubject(subjectId).map(\.value) == [4.0])
        #expect(try repository.forSubject(otherId).map(\.value) == [6.0])
    }

    @Test("Lists all grades newest-created first")
    func listsAllNewestFirst() throws {
        try repository.create(Fixture.grade(subjectId: subjectId, value: 4.0, date: .iso("2025-06-01")))
        try repository.create(Fixture.grade(subjectId: subjectId, value: 5.0, date: .iso("2025-01-01")))

        #expect(try repository.all().map(\.value) == [5.0, 4.0])
    }

    @Test("Pairs each grade with its subject and education for the list screen")
    func listsWithParents() throws {
        try repository.create(Fixture.grade(subjectId: subjectId, value: 5.0))

        let items = try repository.allListItems()

        #expect(items.count == 1)
        #expect(items.first?.subject.name == "Analysis")
        #expect(items.first?.education.name == "Informatik")
    }

    @Test("Counts a subject's grades for the delete confirmation")
    func countsWithinSubject() throws {
        let other = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Algebra")
        )
        let otherId = try #require(other.id)

        try repository.create(Fixture.grade(subjectId: subjectId))
        try repository.create(Fixture.grade(subjectId: subjectId))
        try repository.create(Fixture.grade(subjectId: otherId))

        #expect(try repository.count(forSubject: subjectId) == 2)
        #expect(try repository.count(forSubject: otherId) == 1)
    }

    @Test("Counts an education's grades across all its subjects")
    func countsWithinEducation() throws {
        let otherEducation = try educations.create(Fixture.education(name: "Mathematik"))
        let otherEducationId = try #require(otherEducation.id)
        let otherSubject = try subjects.create(
            Fixture.subject(educationId: otherEducationId, name: "Analysis")
        )
        let secondSubject = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Algebra")
        )

        try repository.create(Fixture.grade(subjectId: subjectId))
        try repository.create(Fixture.grade(subjectId: try #require(secondSubject.id)))
        try repository.create(Fixture.grade(subjectId: try #require(otherSubject.id)))

        #expect(try repository.count(inEducation: educationId) == 2)
        #expect(try repository.count(inEducation: otherEducationId) == 1)
    }

    // MARK: - Updating and deleting

    @Test("Writes every field back and refreshes updatedAt")
    func updateWritesFields() throws {
        var grade = try repository.create(Fixture.grade(subjectId: subjectId, value: 4.0))
        let id = try #require(grade.id)

        grade.value = 5.5
        grade.weight = 0.75
        grade.description = "Nachprüfung"
        grade.date = .iso("2025-09-30")
        grade.updatedAt = Date(timeIntervalSince1970: 0)
        let updated = try repository.update(grade)

        let stored = try #require(try repository.find(id: id))
        #expect(stored.value == 5.5)
        #expect(stored.weight == 0.75)
        #expect(stored.description == "Nachprüfung")
        #expect(stored.date == .iso("2025-09-30"))
        #expect(abs(updated.updatedAt.timeIntervalSinceNow) < 60)
    }

    @Test("Moves a grade to another subject")
    func updateMovesSubject() throws {
        let other = try subjects.create(
            Fixture.subject(educationId: educationId, name: "Algebra")
        )
        let otherId = try #require(other.id)

        var grade = try repository.create(Fixture.grade(subjectId: subjectId))
        grade.subjectId = otherId
        try repository.update(grade)

        #expect(try repository.forSubject(subjectId).isEmpty)
        #expect(try repository.forSubject(otherId).count == 1)
    }

    @Test("Refuses to update a record with no id or no row")
    func updateFailures() throws {
        #expect(throws: RepositoryError.missingIdentifier) {
            try repository.update(Fixture.grade(subjectId: subjectId))
        }

        var missing = Fixture.grade(subjectId: subjectId)
        missing.id = 999
        #expect(throws: RepositoryError.notFound) {
            try repository.update(missing)
        }
    }

    @Test("Deletes and says whether there was anything to delete")
    func deletes() throws {
        let grade = try repository.create(Fixture.grade(subjectId: subjectId))
        let id = try #require(grade.id)

        #expect(try repository.delete(id: id))
        #expect(try repository.find(id: id) == nil)
        #expect(try repository.delete(id: id) == false)
    }
}
