import Foundation
import GRDB

/// Reads and writes `Grade` rows.
public struct GradeRepository: Sendable {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    /// The canonical grade order from SPEC §3.6: newest first, by date then
    /// id. Used on every screen that lists grades — including Home, which in
    /// the old app was the one place that listed them oldest-first.
    static var canonicalOrder: [any SQLOrderingTerm] {
        [
            Grade.Columns.date.desc,
            Grade.Columns.id.desc,
        ]
    }

    // MARK: - Reading

    /// Every grade, newest-created first (§3.6).
    public func all() throws -> [Grade] {
        try database.read { db in
            try Grade.order(Grade.Columns.id.desc).fetchAll(db)
        }
    }

    /// Every grade with its subject and education attached, newest-created
    /// first. Backs the grades list screen (§3.5, §4).
    public func allListItems() throws -> [GradeListItem] {
        try database.read { db in
            let grades = try Grade.order(Grade.Columns.id.desc).fetchAll(db)

            let subjectIds = Set(grades.map(\.subjectId))
            let subjects = try Subject.filter(keys: subjectIds).fetchAll(db)
            let subjectsById = Dictionary(uniqueKeysWithValues: subjects.compactMap { subject in
                subject.id.map { ($0, subject) }
            })
            let educations = try SubjectRepository.educations(for: subjects, in: db)

            return grades.compactMap { grade in
                guard let subject = subjectsById[grade.subjectId],
                      let education = educations[subject.educationId]
                else { return nil }
                return GradeListItem(grade: grade, subject: subject, education: education)
            }
        }
    }

    /// One grade with its subject and education, or `nil` if it isn't there.
    /// Backs the detail screen.
    public func listItem(id: Int64) throws -> GradeListItem? {
        try database.read { db in
            guard let grade = try Grade.fetchOne(db, key: id),
                  let subject = try Subject.fetchOne(db, key: grade.subjectId),
                  let education = try Education.fetchOne(db, key: subject.educationId)
            else { return nil }

            return GradeListItem(grade: grade, subject: subject, education: education)
        }
    }

    /// The grades of one subject, newest first (§3.6).
    public func forSubject(_ subjectId: Int64) throws -> [Grade] {
        try database.read { db in
            try Grade
                .filter(Grade.Columns.subjectId == subjectId)
                .order(Self.canonicalOrder)
                .fetchAll(db)
        }
    }

    public func find(id: Int64) throws -> Grade? {
        try database.read { db in
            try Grade.fetchOne(db, key: id)
        }
    }

    /// How many grades belong to a subject — for the delete confirmation (§4).
    public func count(forSubject subjectId: Int64) throws -> Int {
        try database.read { db in
            try Grade
                .filter(Grade.Columns.subjectId == subjectId)
                .fetchCount(db)
        }
    }

    /// How many grades belong to an education, across all its subjects.
    public func count(inEducation educationId: Int64) throws -> Int {
        try database.read { db in
            try Grade
                .filter(
                    Subject
                        .select(Subject.Columns.id)
                        .filter(Subject.Columns.educationId == educationId)
                        .contains(Grade.Columns.subjectId)
                )
                .fetchCount(db)
        }
    }

    // MARK: - Writing

    /// Inserts a new grade and returns it with its assigned id.
    @discardableResult
    public func create(_ grade: Grade) throws -> Grade {
        var record = grade
        record.id = nil
        record.updatedAt = .now

        return try database.write { db in
            try record.insertAndFetch(db)
        }
    }

    /// Writes every field back, stamping `updatedAt`.
    @discardableResult
    public func update(_ grade: Grade) throws -> Grade {
        guard let id = grade.id else { throw RepositoryError.missingIdentifier }

        var record = grade
        record.updatedAt = .now

        return try database.write { db in
            guard try Grade.exists(db, key: id) else { throw RepositoryError.notFound }
            return try record.updateAndFetch(db)
        }
    }

    /// Returns `false` if there was nothing to delete.
    @discardableResult
    public func delete(id: Int64) throws -> Bool {
        try database.write { db in
            try Grade.deleteOne(db, key: id)
        }
    }
}
