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

    // Each read below is a `static` query plus a one-line instance method
    // that runs it. The split exists so `AppDatabase.observe` can re-run the
    // very same query when the rows it read change — one copy, two callers.

    /// Every education, newest-created first (SPEC §3.6).
    public static func fetchAll(_ db: Database) throws -> [Education] {
        try Education.order(Education.Columns.id.desc).fetchAll(db)
    }

    public func all() throws -> [Education] {
        try database.read(Self.fetchAll)
    }

    /// Educations that are still in progress, newest-created first.
    ///
    /// Backs the subject form's education picker (§4), which offers only
    /// in-progress educations.
    public static func fetchInProgress(_ db: Database) throws -> [Education] {
        try Education
            .filter(Education.Columns.completed == false)
            .order(Education.Columns.id.desc)
            .fetchAll(db)
    }

    public func inProgress() throws -> [Education] {
        try database.read(Self.fetchInProgress)
    }

    public func find(id: Int64) throws -> Education? {
        try database.read { db in
            try Education.fetchOne(db, key: id)
        }
    }

    /// The distinct institutions present in the data, for the institution
    /// filter control (§3.5). Blank and missing values are left out.
    public static func fetchDistinctInstitutions(_ db: Database) throws -> [String] {
        try String.fetchAll(db, sql: """
            SELECT DISTINCT institution FROM Educations
            WHERE institution IS NOT NULL AND TRIM(institution) <> ''
            ORDER BY institution COLLATE NOCASE ASC
            """)
    }

    public func distinctInstitutions() throws -> [String] {
        try database.read(Self.fetchDistinctInstitutions)
    }

    public static func fetchCount(_ db: Database) throws -> Int {
        try Education.fetchCount(db)
    }

    public func count() throws -> Int {
        try database.read(Self.fetchCount)
    }

    // MARK: - Reading whole trees

    /// Every education with its subjects and their grades, newest-created
    /// first (§3.6).
    ///
    /// Three queries no matter how many educations there are, all inside one
    /// read — the list screen needs a computed average per row, and doing
    /// that a row at a time would be a query apiece.
    public static func fetchAllSummaries(_ db: Database) throws -> [EducationSummary] {
        let educations = try Education.order(Education.Columns.id.desc).fetchAll(db)
        let subjects = try Subject.order(SubjectRepository.canonicalOrder).fetchAll(db)
        let subjectsWithGrades = try SubjectRepository.attachGrades(to: subjects, in: db)
        let grouped = Dictionary(grouping: subjectsWithGrades, by: \.subject.educationId)

        return educations.map { education in
            EducationSummary(
                education: education,
                subjects: education.id.flatMap { grouped[$0] } ?? []
            )
        }
    }

    public func allSummaries() throws -> [EducationSummary] {
        try database.read(Self.fetchAllSummaries)
    }

    /// One education with its subjects and their grades, or `nil` if it isn't
    /// there. Backs the detail screen.
    public static func fetchSummary(id: Int64, in db: Database) throws -> EducationSummary? {
        guard let education = try Education.fetchOne(db, key: id) else { return nil }

        let subjects = try Subject
            .filter(Subject.Columns.educationId == id)
            .order(SubjectRepository.canonicalOrder)
            .fetchAll(db)

        return EducationSummary(
            education: education,
            subjects: try SubjectRepository.attachGrades(to: subjects, in: db)
        )
    }

    public func summary(id: Int64) throws -> EducationSummary? {
        try database.read { try Self.fetchSummary(id: id, in: $0) }
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
