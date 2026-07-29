import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("AppDatabase — export")
struct ExportTests {

    private func makeTemporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "scade-export-\(UUID().uuidString).sqlite", directoryHint: .notDirectory)
    }

    @Test("Writes a snapshot that opens and holds the same rows")
    func exportsReadableSnapshot() throws {
        let database = try AppDatabase.inMemory()
        let educations = EducationRepository(database: database)
        let subjects = SubjectRepository(database: database)
        let grades = GradeRepository(database: database)

        let education = try educations.create(Fixture.education(name: "Informatik"))
        let subject = try subjects.create(
            Fixture.subject(educationId: try #require(education.id), name: "Analysis")
        )
        try grades.create(Fixture.grade(subjectId: try #require(subject.id), value: 5.25))

        let url = makeTemporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try database.exportSnapshot(to: url)
        #expect(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))

        // Reopening runs the migrator again, which must find the schema
        // already in place and leave the data alone.
        let reopened = try AppDatabase.open(at: url)
        let restored = EducationRepository(database: reopened)

        #expect(try restored.all().map(\.name) == ["Informatik"])
        #expect(try SubjectRepository(database: reopened).all().count == 1)
        #expect(try GradeRepository(database: reopened).all().map(\.value) == [5.25])
    }

    @Test("Replaces a snapshot that's already there")
    func overwritesExistingFile() throws {
        let database = try AppDatabase.inMemory()
        let url = makeTemporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try database.exportSnapshot(to: url)
        // SQLite refuses to VACUUM INTO an existing path, so a second export
        // to the same place has to succeed on its own.
        try database.exportSnapshot(to: url)

        #expect(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
    }

    @Test("Leaves the source database usable")
    func leavesSourceIntact() throws {
        let database = try AppDatabase.inMemory()
        let educations = EducationRepository(database: database)
        try educations.create(Fixture.education(name: "Informatik"))

        let url = makeTemporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try database.exportSnapshot(to: url)

        try educations.create(Fixture.education(name: "Mathematik"))
        #expect(try educations.count() == 2)
    }
}
