import Foundation
import GRDB

/// A single mark on the Swiss 1–6 scale (6 best, 4 passing).
///
/// `weight` is a plain column here, unlike the old app's separate `Weight`
/// table, so it can never be absent — the `grade.Weight?.Value ?? 1`
/// null-coalescing dance is gone with it (SPEC §2).
public struct Grade: Identifiable, Hashable, Sendable, Codable {
    /// `nil` until the record has been inserted; the repository fills it in.
    public var id: Int64?
    public var subjectId: Int64
    public var value: Double
    /// A multiplier, not a percentage. `1.0` means "one normal unit"; the UI
    /// displays it as `100%` (§3.3).
    public var weight: Double
    public var description: String?
    public var date: CalendarDate
    public var updatedAt: Date

    public init(
        id: Int64? = nil,
        subjectId: Int64,
        value: Double,
        weight: Double = 1.0,
        description: String? = nil,
        date: CalendarDate,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.subjectId = subjectId
        self.value = value
        self.weight = weight
        self.description = description
        self.date = date
        self.updatedAt = updatedAt
    }

    /// Below the Swiss passing mark — drives the red styling in §3.4.
    public var isFailing: Bool {
        GradingScale.isFailing(value)
    }
}

extension Grade: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "Grades"

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let subjectId = Column(CodingKeys.subjectId)
        public static let value = Column(CodingKeys.value)
        public static let weight = Column(CodingKeys.weight)
        public static let description = Column(CodingKeys.description)
        public static let date = Column(CodingKeys.date)
        public static let updatedAt = Column(CodingKeys.updatedAt)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
