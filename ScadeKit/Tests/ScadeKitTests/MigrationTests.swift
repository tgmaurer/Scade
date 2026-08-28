import Foundation
import GRDB
import Testing

@testable import ScadeKit

/// Exercises the migrations as a sequence, not just the schema they end at.
///
/// `SchemaTests` runs against a database migrated all the way in one go,
/// which is what a fresh install gets. This suite starts where an existing
/// install starts — at v1, with rows in it — because that is the case a
/// table rebuild can destroy and a fresh-install test can never catch.
@Suite("Migrations")
struct MigrationTests {

    /// A v1 database holding one education, one subject and two grades.
    private func v1Database() throws -> DatabaseQueue {
        let queue = try DatabaseQueue(configuration: .scade)
        try ScadeMigrator.migrator.migrate(queue, upTo: "v1.initialSchema")

        try queue.write { db -> Void in
            try db.execute(
                sql: """
                    INSERT INTO Educations (id, name, semesters, startDate, endDate)
                    VALUES (1, 'Informatiker EFZ', 8, '2024-08-01', '2028-07-31');

                    INSERT INTO Subjects (id, educationId, name, semester, weight)
                    VALUES (7, 1, 'Mathematik', 2, 1.5);

                    INSERT INTO Grades (id, subjectId, value, weight, date)
                    VALUES (11, 7, 5.5, 1.0, '2026-03-01'),
                           (12, 7, 4.0, 0.5, '2026-04-01');
                    """
            )
        }

        return queue
    }

    @Test("Carries every row through the v2 rebuild, ids and all")
    func keepsRowsThroughTheRebuild() throws {
        let queue = try v1Database()
        try ScadeMigrator.migrator.migrate(queue)

        try queue.read { db in
            #expect(try Education.fetchCount(db) == 1)
            #expect(try Subject.fetchCount(db) == 1)
            #expect(try Grade.fetchCount(db) == 2)

            let subject = try Subject.fetchOne(db, key: 7)
            #expect(subject?.name == "Mathematik")
            #expect(subject?.weight == 1.5)
            #expect(subject?.educationId == 1)

            let grade = try Grade.fetchOne(db, key: 12)
            #expect(grade?.value == 4.0)
            #expect(grade?.weight == 0.5)
            #expect(grade?.subjectId == 7)
        }
    }

    @Test("Takes a zero weight afterwards, where v1 refused one")
    func acceptsZeroWeightsAfterMigrating() throws {
        let queue = try v1Database()

        try queue.write { db -> Void in
            #expect(throws: DatabaseError.self) {
                try db.execute(
                    sql: "INSERT INTO Grades (subjectId, value, weight, date) VALUES (7, 5.0, 0, '2026-05-01')"
                )
            }
        }

        try ScadeMigrator.migrator.migrate(queue)

        try queue.write { db -> Void in
            try db.execute(
                sql: "INSERT INTO Grades (subjectId, value, weight, date) VALUES (7, 5.0, 0, '2026-05-01')"
            )
            try db.execute(
                sql: "INSERT INTO Subjects (educationId, name, semester, weight) VALUES (1, 'Sport', 2, 0)"
            )
        }

        try queue.read { db in
            let grades = try Grade.fetchCount(db)
            let subjects = try Subject.fetchCount(db)

            #expect(grades == 3)
            #expect(subjects == 2)
        }
    }

    @Test("Still refuses a negative weight")
    func stillRefusesNegativeWeights() throws {
        let queue = try v1Database()
        try ScadeMigrator.migrator.migrate(queue)

        try queue.write { db -> Void in
            #expect(throws: DatabaseError.self) {
                try db.execute(
                    sql: "INSERT INTO Grades (subjectId, value, weight, date) VALUES (7, 5.0, -0.5, '2026-05-01')"
                )
            }
        }
    }

    /// The rebuild drops the tables the indexes were on, so they have to be
    /// created again by hand. A missing unique index is invisible until two
    /// duplicate rows exist.
    @Test("Puts the indexes back")
    func restoresTheIndexes() throws {
        let queue = try v1Database()
        try ScadeMigrator.migrator.migrate(queue)

        try queue.read { db in
            let names = try String.fetchSet(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'"
            )
            #expect(names == ["idx_subjects_education", "idx_grades_subject", "idx_subjects_unique"])
        }

        try queue.write { db -> Void in
            #expect(throws: DatabaseError.self) {
                try db.execute(
                    sql: "INSERT INTO Subjects (educationId, name, semester) VALUES (1, 'Mathematik', 2)"
                )
            }
        }
    }

    /// Cascade delete is the only thing holding grades to their subject, and
    /// it lives in the rebuilt table's foreign key clause.
    @Test("Keeps the cascade from subject to grade")
    func keepsTheCascade() throws {
        let queue = try v1Database()
        try ScadeMigrator.migrator.migrate(queue)

        try queue.write { db -> Void in
            try db.execute(sql: "DELETE FROM Subjects WHERE id = 7")
            #expect(try Grade.fetchCount(db) == 0)
        }
    }

    /// And from education to subject, which spans a table that was rebuilt
    /// and one that wasn't.
    @Test("Keeps the cascade from education to subject")
    func keepsTheEducationCascade() throws {
        let queue = try v1Database()
        try ScadeMigrator.migrator.migrate(queue)

        try queue.write { db -> Void in
            try db.execute(sql: "DELETE FROM Educations WHERE id = 1")
            #expect(try Subject.fetchCount(db) == 0)
            #expect(try Grade.fetchCount(db) == 0)
        }
    }
}
