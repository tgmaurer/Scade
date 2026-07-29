import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("EducationRepository")
struct EducationRepositoryTests {
    let database: AppDatabase
    let repository: EducationRepository

    init() throws {
        database = try .inMemory()
        repository = EducationRepository(database: database)
    }

    // MARK: - Creating

    @Test("Assigns an id on insert and reads the record back")
    func createAssignsIdentifier() throws {
        let created = try repository.create(Fixture.education(name: "Informatik"))
        let id = try #require(created.id)

        #expect(created.name == "Informatik")
        #expect(try repository.find(id: id) == created)
    }

    /// §3.4: educations are always born in progress. Completion is reachable
    /// only through `update`, so a form can't create one that's already done.
    @Test("Forces a new education to be in progress")
    func createIgnoresCompletion() throws {
        let created = try repository.create(Fixture.education(completed: true))

        #expect(created.completed == false)
    }

    @Test("Ignores an id supplied by the caller")
    func createIgnoresSuppliedIdentifier() throws {
        var education = Fixture.education()
        education.id = 999

        let created = try repository.create(education)

        #expect(created.id != 999)
    }

    @Test("Stamps updatedAt at insert time, ignoring whatever was passed in")
    func createStampsTimestamp() throws {
        var education = Fixture.education()
        education.updatedAt = Date(timeIntervalSince1970: 0)

        let created = try repository.create(education)

        #expect(abs(created.updatedAt.timeIntervalSinceNow) < 60)
    }

    @Test("Keeps every field it was given")
    func createRoundTripsFields() throws {
        let education = Fixture.education(
            name: "Angewandte Informatik",
            description: "Bachelorstudium",
            semesters: 6,
            startDate: .iso("2024-09-01"),
            endDate: .iso("2027-08-31"),
            institution: "ETH Zürich"
        )

        let created = try repository.create(education)

        #expect(created.name == education.name)
        #expect(created.description == education.description)
        #expect(created.semesters == education.semesters)
        #expect(created.startDate == education.startDate)
        #expect(created.endDate == education.endDate)
        #expect(created.institution == education.institution)
    }

    // MARK: - Reading

    @Test("Returns nothing for an id that isn't there")
    func findMissingReturnsNil() throws {
        #expect(try repository.find(id: 999) == nil)
    }

    /// §3.6: top-level lists are newest-created first.
    @Test("Lists educations newest-created first")
    func listsNewestFirst() throws {
        try repository.create(Fixture.education(name: "First"))
        try repository.create(Fixture.education(name: "Second"))
        try repository.create(Fixture.education(name: "Third"))

        #expect(try repository.all().map(\.name) == ["Third", "Second", "First"])
    }

    @Test("Lists only in-progress educations for the subject form's picker")
    func listsInProgressOnly() throws {
        let finished = try repository.create(Fixture.education(name: "Finished"))
        try repository.create(Fixture.education(name: "Ongoing"))

        var completed = finished
        completed.completed = true
        try repository.update(completed)

        #expect(try repository.inProgress().map(\.name) == ["Ongoing"])
    }

    @Test("Reports the distinct institutions in the data")
    func listsDistinctInstitutions() throws {
        try repository.create(Fixture.education(name: "A", institution: "ETH Zürich"))
        try repository.create(Fixture.education(name: "B", institution: "ETH Zürich"))
        try repository.create(Fixture.education(name: "C", institution: "Universität Basel"))
        try repository.create(Fixture.education(name: "D", institution: nil))
        try repository.create(Fixture.education(name: "E", institution: "   "))

        #expect(try repository.distinctInstitutions() == ["ETH Zürich", "Universität Basel"])
    }

    @Test("Counts what's stored")
    func counts() throws {
        #expect(try repository.count() == 0)

        try repository.create(Fixture.education())
        try repository.create(Fixture.education(name: "Second"))

        #expect(try repository.count() == 2)
    }

    /// Two reads are two queries — there is nothing cached in between.
    @Test("Sees writes made after an earlier read")
    func readsAreNotCached() throws {
        #expect(try repository.all().isEmpty)

        try repository.create(Fixture.education())

        #expect(try repository.all().count == 1)
    }

    // MARK: - Updating

    @Test("Writes every field back")
    func updateWritesFields() throws {
        var education = try repository.create(Fixture.education(name: "Informatik"))
        let id = try #require(education.id)

        education.name = "Wirtschaftsinformatik"
        education.description = "Umbenannt"
        education.semesters = 8
        education.institution = "Universität Basel"
        education.completed = true
        try repository.update(education)

        let stored = try #require(try repository.find(id: id))
        #expect(stored.name == "Wirtschaftsinformatik")
        #expect(stored.description == "Umbenannt")
        #expect(stored.semesters == 8)
        #expect(stored.institution == "Universität Basel")
        #expect(stored.completed)
    }

    @Test("Refreshes updatedAt on every write")
    func updateStampsTimestamp() throws {
        var education = try repository.create(Fixture.education())
        education.updatedAt = Date(timeIntervalSince1970: 0)

        let updated = try repository.update(education)

        #expect(abs(updated.updatedAt.timeIntervalSinceNow) < 60)
    }

    @Test("Refuses to update a record that was never inserted")
    func updateWithoutIdentifierFails() {
        #expect(throws: RepositoryError.missingIdentifier) {
            try repository.update(Fixture.education())
        }
    }

    @Test("Refuses to update a record that no longer exists")
    func updateMissingRecordFails() throws {
        var education = Fixture.education()
        education.id = 999

        #expect(throws: RepositoryError.notFound) {
            try repository.update(education)
        }
    }

    // MARK: - Deleting

    @Test("Deletes and says whether there was anything to delete")
    func deletes() throws {
        let education = try repository.create(Fixture.education())
        let id = try #require(education.id)

        #expect(try repository.delete(id: id))
        #expect(try repository.find(id: id) == nil)
        #expect(try repository.delete(id: id) == false)
    }

    @Test("Takes the education's subjects and grades down with it")
    func deleteCascades() throws {
        let subjects = SubjectRepository(database: database)
        let grades = GradeRepository(database: database)

        let education = try repository.create(Fixture.education())
        let educationId = try #require(education.id)
        let subject = try subjects.create(Fixture.subject(educationId: educationId))
        let subjectId = try #require(subject.id)
        try grades.create(Fixture.grade(subjectId: subjectId))

        try repository.delete(id: educationId)

        #expect(try subjects.all().isEmpty)
        #expect(try grades.all().isEmpty)
    }
}
