import Foundation
import GRDB

/// Reads and writes `Subject` rows, plus the fully-fetched subject/grade sets
/// the average calculations require.
public struct SubjectRepository: Sendable {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    /// The canonical subject order from SPEC §3.6: semester descending, then
    /// name ascending, then id descending. Used on every screen that lists
    /// subjects within an education.
    static var canonicalOrder: [any SQLOrderingTerm] {
        [
            Subject.Columns.semester.desc,
            Subject.Columns.name.asc,
            Subject.Columns.id.desc,
        ]
    }

    // MARK: - Reading

    /// Every subject, newest-created first (§3.6).
    public func all() throws -> [Subject] {
        try database.read { db in
            try Subject.order(Subject.Columns.id.desc).fetchAll(db)
        }
    }

    /// Every subject with its education attached, newest-created first.
    ///
    /// Backs the subjects list screen, which shows the parent education and
    /// searches its name (§3.5, §4).
    public func allListItems() throws -> [SubjectListItem] {
        try database.read { db in
            let subjects = try Subject.order(Subject.Columns.id.desc).fetchAll(db)
            let educations = try Self.educations(for: subjects, in: db)

            return subjects.compactMap { subject in
                guard let education = educations[subject.educationId] else { return nil }
                return SubjectListItem(subject: subject, education: education)
            }
        }
    }

    /// The subjects of one education, in canonical order (§3.6).
    public func inEducation(_ educationId: Int64) throws -> [Subject] {
        try database.read { db in
            try Subject
                .filter(Subject.Columns.educationId == educationId)
                .order(Self.canonicalOrder)
                .fetchAll(db)
        }
    }

    /// The subjects of one education restricted to a single semester, in
    /// canonical order. Backs the Home screen's semester filter (§4).
    public func inEducation(_ educationId: Int64, semester: Int) throws -> [Subject] {
        try database.read { db in
            try Subject
                .filter(Subject.Columns.educationId == educationId)
                .filter(Subject.Columns.semester == semester)
                .order(Self.canonicalOrder)
                .fetchAll(db)
        }
    }

    /// Subjects that are still in progress, newest-created first.
    ///
    /// Backs the grade form's subject picker (§4), which offers only
    /// in-progress subjects.
    public func inProgress() throws -> [Subject] {
        try database.read { db in
            try Subject
                .filter(Subject.Columns.completed == false)
                .order(Subject.Columns.id.desc)
                .fetchAll(db)
        }
    }

    public func find(id: Int64) throws -> Subject? {
        try database.read { db in
            try Subject.fetchOne(db, key: id)
        }
    }

    /// How many subjects belong to an education — for the delete
    /// confirmation, which spells out what the cascade will take with it (§4).
    public func count(inEducation educationId: Int64) throws -> Int {
        try database.read { db in
            try Subject
                .filter(Subject.Columns.educationId == educationId)
                .fetchCount(db)
        }
    }

    // MARK: - Reading for averages

    /// One subject with every one of its grades.
    ///
    /// Both queries run inside a single read, so the result is a consistent
    /// snapshot rather than two reads that might straddle a write.
    public func subjectWithGrades(id: Int64) throws -> SubjectGrades? {
        try database.read { db in
            guard let subject = try Subject.fetchOne(db, key: id) else { return nil }
            let grades = try Grade
                .filter(Grade.Columns.subjectId == id)
                .order(GradeRepository.canonicalOrder)
                .fetchAll(db)
            return SubjectGrades(subject: subject, grades: grades)
        }
    }

    /// Every subject of an education with every one of their grades, in
    /// canonical subject order.
    ///
    /// This is the input to the education rollup (§3.2). Everything is
    /// materialised here — two queries, no lazy relationship — precisely
    /// because the old app once averaged an unpopulated collection and got a
    /// silent zero.
    public func subjectsWithGrades(educationId: Int64) throws -> [SubjectGrades] {
        try database.read { db in
            let subjects = try Subject
                .filter(Subject.Columns.educationId == educationId)
                .order(Self.canonicalOrder)
                .fetchAll(db)

            return try Self.attachGrades(to: subjects, in: db)
        }
    }

    /// The same as `subjectsWithGrades(educationId:)`, restricted to one
    /// semester — the Home screen's filtered average (§4).
    public func subjectsWithGrades(educationId: Int64, semester: Int) throws -> [SubjectGrades] {
        try database.read { db in
            let subjects = try Subject
                .filter(Subject.Columns.educationId == educationId)
                .filter(Subject.Columns.semester == semester)
                .order(Self.canonicalOrder)
                .fetchAll(db)

            return try Self.attachGrades(to: subjects, in: db)
        }
    }

    // MARK: - Writing

    /// Inserts a new subject and returns it with its assigned id.
    ///
    /// `completed` is forced to `false` and `id` is ignored: §3.4 requires
    /// subjects to be born in progress.
    ///
    /// - Throws: `RepositoryError.duplicateSubject` if the education already
    ///   has a subject with this name in this semester.
    @discardableResult
    public func create(_ subject: Subject) throws -> Subject {
        var record = subject
        record.id = nil
        record.completed = false
        record.updatedAt = .now

        return try Self.mappingConstraintErrors {
            try database.write { db in
                try record.insertAndFetch(db)
            }
        }
    }

    /// Writes every field back, stamping `updatedAt`.
    ///
    /// - Throws: `RepositoryError.duplicateSubject` if the change would
    ///   collide with another subject in the same education and semester.
    @discardableResult
    public func update(_ subject: Subject) throws -> Subject {
        guard let id = subject.id else { throw RepositoryError.missingIdentifier }

        var record = subject
        record.updatedAt = .now

        return try Self.mappingConstraintErrors {
            try database.write { db in
                guard try Subject.exists(db, key: id) else { throw RepositoryError.notFound }
                return try record.updateAndFetch(db)
            }
        }
    }

    /// Deletes the subject and — via `ON DELETE CASCADE` — its grades.
    /// Returns `false` if there was nothing to delete.
    @discardableResult
    public func delete(id: Int64) throws -> Bool {
        try database.write { db in
            try Subject.deleteOne(db, key: id)
        }
    }

    // MARK: - Helpers

    /// Fetches all grades for `subjects` in one query and groups them.
    private static func attachGrades(to subjects: [Subject], in db: Database) throws -> [SubjectGrades] {
        let ids = subjects.compactMap(\.id)
        guard ids.isEmpty == false else {
            return subjects.map { SubjectGrades(subject: $0, grades: []) }
        }

        let grades = try Grade
            .filter(ids.contains(Grade.Columns.subjectId))
            .order(GradeRepository.canonicalOrder)
            .fetchAll(db)
        let grouped = Dictionary(grouping: grades, by: \.subjectId)

        return subjects.map { subject in
            let subjectGrades = subject.id.flatMap { grouped[$0] } ?? []
            return SubjectGrades(subject: subject, grades: subjectGrades)
        }
    }

    /// Fetches the educations referenced by `subjects`, keyed by id.
    static func educations(for subjects: [Subject], in db: Database) throws -> [Int64: Education] {
        let ids = Set(subjects.map(\.educationId))
        guard ids.isEmpty == false else { return [:] }

        let educations = try Education.filter(keys: ids).fetchAll(db)
        return Dictionary(uniqueKeysWithValues: educations.compactMap { education in
            education.id.map { ($0, education) }
        })
    }

    /// Translates the `idx_subjects_unique` violation into a domain error.
    private static func mappingConstraintErrors<T>(_ work: () throws -> T) throws -> T {
        do {
            return try work()
        } catch let error as DatabaseError where error.isUniqueConstraintViolation {
            throw RepositoryError.duplicateSubject
        }
    }
}
