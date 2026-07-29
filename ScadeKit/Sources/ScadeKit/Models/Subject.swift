import Foundation
import GRDB

/// A subject within an education. `weight` scales how much this subject
/// contributes to its education's overall average (SPEC §3.2) — it has no
/// counterpart in the old app.
public struct Subject: Identifiable, Hashable, Sendable, Codable {
    /// `nil` until the record has been inserted; the repository fills it in.
    public var id: Int64?
    public var educationId: Int64
    public var name: String
    public var description: String?
    public var semester: Int
    /// A multiplier, not a percentage. `1.0` means "one normal unit"; the UI
    /// displays it as `100%` (§3.3).
    public var weight: Double
    public var completed: Bool
    public var updatedAt: Date

    public init(
        id: Int64? = nil,
        educationId: Int64,
        name: String,
        description: String? = nil,
        semester: Int,
        weight: Double = 1.0,
        completed: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.educationId = educationId
        self.name = name
        self.description = description
        self.semester = semester
        self.weight = weight
        self.completed = completed
        self.updatedAt = updatedAt
    }
}

extension Subject: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "Subjects"

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let educationId = Column(CodingKeys.educationId)
        public static let name = Column(CodingKeys.name)
        public static let description = Column(CodingKeys.description)
        public static let semester = Column(CodingKeys.semester)
        public static let weight = Column(CodingKeys.weight)
        public static let completed = Column(CodingKeys.completed)
        public static let updatedAt = Column(CodingKeys.updatedAt)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
