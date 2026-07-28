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

        return migrator
    }
}
