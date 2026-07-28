import Foundation
import GRDB

/// Reads and writes `Education` rows.
///
/// Holds a connection and nothing else — no identity map, no cached rows.
/// Two calls to `all()` are two queries, and the second one sees whatever the
/// database says at that moment.
public struct EducationRepository: Sendable {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - Reading

    /// Every education, newest-created first (SPEC §3.6).
    public func all() throws -> [Education] {
        try database.read { db in
            try Education.order(Education.Columns.id.desc).fetchAll(db)
        }
    }

    /// Educations that are still in progress, newest-created first.
    ///
    /// Backs the subject form's education picker (§4), which offers only
    /// in-progress educations.
    public func inProgress() throws -> [Education] {
        try database.read { db in
            try Education
                .filter(Education.Columns.completed == false)
                .order(Education.Columns.id.desc)
                .fetchAll(db)
        }
    }

    public func find(id: Int64) throws -> Education? {
        try database.read { db in
            try Education.fetchOne(db, key: id)
        }
    }

    /// The distinct institutions present in the data, for the institution
    /// filter control (§3.5). Blank and missing values are left out.
    public func distinctInstitutions() throws -> [String] {
        try database.read { db in
            try String.fetchAll(db, sql: """
                SELECT DISTINCT institution FROM Educations
                WHERE institution IS NOT NULL AND TRIM(institution) <> ''
                ORDER BY institution COLLATE NOCASE ASC
                """)
        }
    }

    public func count() throws -> Int {
        try database.read { db in
            try Education.fetchCount(db)
        }
    }

    // MARK: - Writing

    /// Inserts a new education and returns it with its assigned id.
    ///
    /// `completed` is forced to `false` and `id` is ignored: §3.4 requires
    /// educations to be born in progress, so completion is reachable only
    /// through `update`.
    @discardableResult
    public func create(_ education: Education) throws -> Education {
        var record = education
        record.id = nil
        record.completed = false
        record.updatedAt = .now

        return try database.write { db in
            try record.insertAndFetch(db)
        }
    }

    /// Writes every field back, stamping `updatedAt`.
    @discardableResult
    public func update(_ education: Education) throws -> Education {
        guard let id = education.id else { throw RepositoryError.missingIdentifier }

        var record = education
        record.updatedAt = .now

        return try database.write { db in
            guard try Education.exists(db, key: id) else { throw RepositoryError.notFound }
            return try record.updateAndFetch(db)
        }
    }

    /// Deletes the education and — via `ON DELETE CASCADE` — its subjects and
    /// their grades. Returns `false` if there was nothing to delete.
    @discardableResult
    public func delete(id: Int64) throws -> Bool {
        try database.write { db in
            try Education.deleteOne(db, key: id)
        }
    }
}
