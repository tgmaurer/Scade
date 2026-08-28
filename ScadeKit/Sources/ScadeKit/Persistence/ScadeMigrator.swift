import Foundation
import GRDB

/// The database schema, defined as raw SQL.
///
/// Written out longhand rather than built with GRDB's table builder so it can
/// be diffed line-for-line against SPEC §2 — the `COLLATE NOCASE` clauses and
/// `CHECK` constraints are the contract, and an approximation of them would
/// be a silent regression.
public enum ScadeMigrator {
    public static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1.initialSchema") { db in
            try db.execute(sql: """
                CREATE TABLE Educations (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT NOT NULL COLLATE NOCASE,
                    description TEXT COLLATE NOCASE,
                    semesters   INTEGER NOT NULL CHECK (semesters >= 1),
                    startDate   TEXT NOT NULL,
                    endDate     TEXT NOT NULL CHECK (endDate >= startDate),
                    institution TEXT COLLATE NOCASE,
                    completed   INTEGER NOT NULL DEFAULT 0,
                    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );

                CREATE TABLE Subjects (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    educationId INTEGER NOT NULL REFERENCES Educations(id) ON DELETE CASCADE,
                    name        TEXT NOT NULL COLLATE NOCASE,
                    description TEXT COLLATE NOCASE,
                    semester    INTEGER NOT NULL CHECK (semester >= 1),
                    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight > 0),
                    completed   INTEGER NOT NULL DEFAULT 0,
                    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );

                CREATE TABLE Grades (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    subjectId   INTEGER NOT NULL REFERENCES Subjects(id) ON DELETE CASCADE,
                    value       REAL NOT NULL CHECK (value >= 1.0 AND value <= 6.0),
                    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight > 0),
                    description TEXT COLLATE NOCASE,
                    date        TEXT NOT NULL,
                    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );

                CREATE INDEX idx_subjects_education ON Subjects(educationId);
                CREATE INDEX idx_grades_subject ON Grades(subjectId);

                -- Closes a gap the old app had: uniqueness was app-code-only,
                -- not enforced by the DB, leaving a race-condition window.
                CREATE UNIQUE INDEX idx_subjects_unique ON Subjects(educationId, name, semester);
                """)
        }

        // A weight of 0 — "this doesn't count" — is a weight, not a missing
        // one, and v1 refused it. SQLite can't alter a CHECK constraint, so
        // both tables are rebuilt: new table, copy, drop, rename, and the
        // indexes put back by hand because they go with the table they were
        // on. Registered without `foreignKeyChecks: .immediate`, which is
        // what lets `Grades` outlive the `Subjects` it points at for the two
        // statements in between; the migrator checks the keys again at the
        // end.
        //
        // Column lists are written out on both sides rather than `SELECT *`.
        // The two schemas agree today, and a list that has to be edited to
        // stay wrong is the point.
        migrator.registerMigration("v2.zeroWeights") { db in
            try db.execute(sql: """
                CREATE TABLE Subjects_new (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    educationId INTEGER NOT NULL REFERENCES Educations(id) ON DELETE CASCADE,
                    name        TEXT NOT NULL COLLATE NOCASE,
                    description TEXT COLLATE NOCASE,
                    semester    INTEGER NOT NULL CHECK (semester >= 1),
                    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
                    completed   INTEGER NOT NULL DEFAULT 0,
                    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );

                CREATE TABLE Grades_new (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    subjectId   INTEGER NOT NULL REFERENCES Subjects(id) ON DELETE CASCADE,
                    value       REAL NOT NULL CHECK (value >= 1.0 AND value <= 6.0),
                    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
                    description TEXT COLLATE NOCASE,
                    date        TEXT NOT NULL,
                    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );

                INSERT INTO Subjects_new
                    (id, educationId, name, description, semester, weight, completed, updatedAt)
                SELECT
                    id, educationId, name, description, semester, weight, completed, updatedAt
                FROM Subjects;

                INSERT INTO Grades_new
                    (id, subjectId, value, weight, description, date, updatedAt)
                SELECT
                    id, subjectId, value, weight, description, date, updatedAt
                FROM Grades;

                DROP TABLE Grades;
                DROP TABLE Subjects;

                ALTER TABLE Subjects_new RENAME TO Subjects;
                ALTER TABLE Grades_new RENAME TO Grades;

                CREATE INDEX idx_subjects_education ON Subjects(educationId);
                CREATE INDEX idx_grades_subject ON Grades(subjectId);
                CREATE UNIQUE INDEX idx_subjects_unique ON Subjects(educationId, name, semester);
                """)
        }

        return migrator
    }
}
