import Foundation
import GRDB
import Testing

@testable import ScadeKit

/// Exercises the schema through raw SQL rather than the repositories, so
/// these tests fail if a constraint is missing even when the Swift layer
/// happens to be checking the same thing.
@Suite("Schema")
struct SchemaTests {
    let database: AppDatabase

    init() throws {
        database = try .inMemory()
    }

    // MARK: - Educations

    @Test("Rejects an education with fewer than one semester")
    func rejectsZeroSemesters() throws {
        try database.write { db in
            #expect(throws: DatabaseError.self) {
                try insertEducation(db, semesters: 0)
            }
            #expect(throws: DatabaseError.self) {
                try insertEducation(db, semesters: -1)
            }
        }
    }

    @Test("Rejects an education whose end date precedes its start date")
    func rejectsInvertedDateRange() throws {
        try database.write { db in
            #expect(throws: DatabaseError.self) {
                try insertEducation(db, startDate: "2026-01-02", endDate: "2026-01-01")
            }

            // Same day is fine — the range is inclusive.
            try insertEducation(db, startDate: "2026-01-01", endDate: "2026-01-01")
        }
    }

    // MARK: - Subjects

    @Test("Rejects a subject before the first semester")
    func rejectsZeroSemester() throws {
        try database.write { db in
            let educationId = try insertEducation(db)

            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: educationId, semester: 0)
            }
        }
    }

    @Test("Rejects a non-positive subject weight", arguments: [0.0, -1.0, -0.001])
    func rejectsNonPositiveSubjectWeight(weight: Double) throws {
        try database.write { db in
            let educationId = try insertEducation(db)

            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: educationId, weight: weight)
            }
        }
    }

    @Test("Rejects a subject pointing at an education that isn't there")
    func enforcesSubjectForeignKey() throws {
        try database.write { db -> Void in
            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: 999)
            }
        }
    }

    @Test("Rejects a second subject with the same education, name and semester")
    func enforcesSubjectUniqueness() throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            try insertSubject(db, educationId: educationId, name: "Analysis", semester: 1)

            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: educationId, name: "Analysis", semester: 1)
            }
        }
    }

    /// The `COLLATE NOCASE` on `Subjects.name` extends to the unique index,
    /// so casing alone doesn't make a new subject.
    @Test("Treats subject names case-insensitively when enforcing uniqueness")
    func subjectUniquenessIgnoresCase() throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            try insertSubject(db, educationId: educationId, name: "Analysis", semester: 1)

            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: educationId, name: "analysis", semester: 1)
            }
            #expect(throws: DatabaseError.self) {
                try insertSubject(db, educationId: educationId, name: "ANALYSIS", semester: 1)
            }
        }
    }

    @Test("Allows the same subject name in another semester or another education")
    func subjectUniquenessIsScoped() throws {
        try database.write { db in
            let first = try insertEducation(db, name: "Informatik")
            let second = try insertEducation(db, name: "Mathematik")

            try insertSubject(db, educationId: first, name: "Analysis", semester: 1)
            try insertSubject(db, educationId: first, name: "Analysis", semester: 2)
            try insertSubject(db, educationId: second, name: "Analysis", semester: 1)

            #expect(try Subject.fetchCount(db) == 3)
        }
    }

    // MARK: - Grades

    @Test("Rejects a grade outside the 1–6 scale", arguments: [0.0, 0.99, 6.01, 7.0, -1.0])
    func rejectsOutOfScaleGrade(value: Double) throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            let subjectId = try insertSubject(db, educationId: educationId)

            #expect(throws: DatabaseError.self) {
                try insertGrade(db, subjectId: subjectId, value: value)
            }
        }
    }

    @Test("Accepts both ends of the 1–6 scale", arguments: [1.0, 4.0, 5.25, 6.0])
    func acceptsInScaleGrade(value: Double) throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            let subjectId = try insertSubject(db, educationId: educationId)

            try insertGrade(db, subjectId: subjectId, value: value)
            #expect(try Grade.fetchCount(db) == 1)
        }
    }

    @Test("Rejects a non-positive grade weight", arguments: [0.0, -1.0])
    func rejectsNonPositiveGradeWeight(weight: Double) throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            let subjectId = try insertSubject(db, educationId: educationId)

            #expect(throws: DatabaseError.self) {
                try insertGrade(db, subjectId: subjectId, weight: weight)
            }
        }
    }

    @Test("Rejects a grade pointing at a subject that isn't there")
    func enforcesGradeForeignKey() throws {
        try database.write { db -> Void in
            #expect(throws: DatabaseError.self) {
                try insertGrade(db, subjectId: 999)
            }
        }
    }

    // MARK: - Cascades

    @Test("Deleting an education takes its subjects and grades with it")
    func educationDeleteCascades() throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            let subjectId = try insertSubject(db, educationId: educationId)
            try insertGrade(db, subjectId: subjectId)

            try db.execute(sql: "DELETE FROM Educations WHERE id = ?", arguments: [educationId])

            #expect(try Subject.fetchCount(db) == 0)
            #expect(try Grade.fetchCount(db) == 0)
        }
    }

    @Test("Deleting a subject takes its grades with it")
    func subjectDeleteCascades() throws {
        try database.write { db in
            let educationId = try insertEducation(db)
            let subjectId = try insertSubject(db, educationId: educationId)
            try insertGrade(db, subjectId: subjectId)

            try db.execute(sql: "DELETE FROM Subjects WHERE id = ?", arguments: [subjectId])

            #expect(try Grade.fetchCount(db) == 0)
            #expect(try Education.fetchCount(db) == 1)
        }
    }

    // MARK: - Structure

    @Test("Creates the indexes from the spec")
    func createsIndexes() throws {
        let names = try database.read { db in
            try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'"
            )
        }

        #expect(Set(names) == ["idx_subjects_education", "idx_grades_subject", "idx_subjects_unique"])
    }

    /// The `updatedAt` default is written by SQLite in `…THH:MM:SS.SSSZ` form
    /// while GRDB writes `… HH:MM:SS.SSS`. Both have to decode, or a row
    /// inserted by anything other than a repository would fail to read back.
    @Test("Decodes the timestamp format the schema default produces")
    func decodesDefaultTimestamp() throws {
        let education = try database.write { db -> Education in
            let id = try insertEducation(db)
            return try #require(try Education.fetchOne(db, key: id))
        }

        #expect(abs(education.updatedAt.timeIntervalSinceNow) < 60)
    }

    /// Confirms `CalendarDate` reaches SQLite as plain `yyyy-MM-dd` text
    /// rather than being encoded some other way on the way through the record
    /// coder — the `CHECK` constraint and `ORDER BY` both depend on it.
    @Test("Stores calendar dates as yyyy-MM-dd text")
    func storesCalendarDatesAsText() throws {
        let repository = EducationRepository(database: database)
        try repository.create(
            Fixture.education(startDate: .iso("2024-09-01"), endDate: .iso("2027-08-31"))
        )

        let stored = try database.read { db in
            try Row.fetchOne(db, sql: "SELECT startDate, endDate FROM Educations")
        }
        let row = try #require(stored)

        #expect(row["startDate"] == "2024-09-01")
        #expect(row["endDate"] == "2027-08-31")
    }

    // MARK: - Raw inserts

    @discardableResult
    private func insertEducation(
        _ db: Database,
        name: String = "Informatik",
        semesters: Int = 6,
        startDate: String = "2024-09-01",
        endDate: String = "2027-08-31"
    ) throws -> Int64 {
        try db.execute(
            sql: """
                INSERT INTO Educations (name, semesters, startDate, endDate)
                VALUES (?, ?, ?, ?)
                """,
            arguments: [name, semesters, startDate, endDate]
        )
        return db.lastInsertedRowID
    }

    @discardableResult
    private func insertSubject(
        _ db: Database,
        educationId: Int64,
        name: String = "Analysis",
        semester: Int = 1,
        weight: Double = 1.0
    ) throws -> Int64 {
        try db.execute(
            sql: """
                INSERT INTO Subjects (educationId, name, semester, weight)
                VALUES (?, ?, ?, ?)
                """,
            arguments: [educationId, name, semester, weight]
        )
        return db.lastInsertedRowID
    }

    @discardableResult
    private func insertGrade(
        _ db: Database,
        subjectId: Int64,
        value: Double = 5.0,
        weight: Double = 1.0,
        date: String = "2025-01-15"
    ) throws -> Int64 {
        try db.execute(
            sql: """
                INSERT INTO Grades (subjectId, value, weight, date)
                VALUES (?, ?, ?, ?)
                """,
            arguments: [subjectId, value, weight, date]
        )
        return db.lastInsertedRowID
    }
}
