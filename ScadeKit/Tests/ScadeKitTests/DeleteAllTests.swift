import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("AppDatabase — delete all")
struct DeleteAllTests {

    /// One education, two subjects, three grades — enough that a partial
    /// delete would show up as a non-zero count somewhere.
    private func makePopulatedDatabase() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        let educations = EducationRepository(database: database)
        let subjects = SubjectRepository(database: database)
        let grades = GradeRepository(database: database)

        let education = try educations.create(Fixture.education(name: "Informatik"))
        let educationId = try #require(education.id)

        let analysis = try subjects.create(Fixture.subject(educationId: educationId, name: "Analysis"))
        let algebra = try subjects.create(Fixture.subject(educationId: educationId, name: "Algebra"))

        try grades.create(Fixture.grade(subjectId: try #require(analysis.id), value: 5.5))
        try grades.create(Fixture.grade(subjectId: try #require(analysis.id), value: 4.0))
        try grades.create(Fixture.grade(subjectId: try #require(algebra.id), value: 3.5))

        return database
    }

    @Test("Empties every table")
    func removesAllRecords() throws {
        let database = try makePopulatedDatabase()

        try database.deleteAllRecords()

        #expect(try EducationRepository(database: database).all().isEmpty)
        #expect(try SubjectRepository(database: database).all().isEmpty)
        #expect(try GradeRepository(database: database).all().isEmpty)
    }

    @Test("Keeps the schema, so the app is usable straight afterwards")
    func leavesSchemaIntact() throws {
        let database = try makePopulatedDatabase()
        try database.deleteAllRecords()

        let educations = EducationRepository(database: database)
        let education = try educations.create(Fixture.education(name: "Mathematik"))

        #expect(try educations.count() == 1)
        // The foreign key still resolves, which it wouldn't if the tables had
        // been dropped and recreated without their constraints.
        let subjects = SubjectRepository(database: database)
        try subjects.create(
            Fixture.subject(educationId: try #require(education.id), name: "Topologie")
        )
        #expect(try subjects.all().count == 1)
    }

    @Test("Does nothing to an already-empty database")
    func toleratesEmptyDatabase() throws {
        let database = try AppDatabase.inMemory()

        try database.deleteAllRecords()
        try database.deleteAllRecords()

        #expect(try EducationRepository(database: database).count() == 0)
    }

    @Test("Leaves an export taken beforehand untouched")
    func doesNotAffectAnExistingSnapshot() throws {
        let database = try makePopulatedDatabase()
        let url = FileManager.default.temporaryDirectory
            .appending(path: "scade-reset-\(UUID().uuidString).sqlite", directoryHint: .notDirectory)
        defer { try? FileManager.default.removeItem(at: url) }

        try database.exportSnapshot(to: url)
        try database.deleteAllRecords()

        // The whole reason it's safe to offer this next to a backup button.
        let restored = try AppDatabase.open(at: url)
        #expect(try EducationRepository(database: restored).all().map(\.name) == ["Informatik"])
        #expect(try GradeRepository(database: restored).all().count == 3)
    }
}
