import Foundation
import GRDB

/// A course of study — the top of the hierarchy. Owns subjects, which own
/// grades; deleting one cascades all the way down (SPEC §2).
public struct Education: Identifiable, Hashable, Sendable, Codable {
    /// `nil` until the record has been inserted; the repository fills it in.
    public var id: Int64?
    public var name: String
    public var description: String?
    public var semesters: Int
    public var startDate: CalendarDate
    public var endDate: CalendarDate
    public var institution: String?
    public var completed: Bool
    public var updatedAt: Date

    public init(
        id: Int64? = nil,
        name: String,
        description: String? = nil,
        semesters: Int,
        startDate: CalendarDate,
        endDate: CalendarDate,
        institution: String? = nil,
        completed: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.semesters = semesters
        self.startDate = startDate
        self.endDate = endDate
        self.institution = institution
        self.completed = completed
        self.updatedAt = updatedAt
    }

    /// The inclusive range a grade's date must fall inside (§3.4).
    public var dateRange: ClosedRange<CalendarDate>? {
        startDate <= endDate ? startDate...endDate : nil
    }
}

extension Education: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "Educations"

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let description = Column(CodingKeys.description)
        public static let semesters = Column(CodingKeys.semesters)
        public static let startDate = Column(CodingKeys.startDate)
        public static let endDate = Column(CodingKeys.endDate)
        public static let institution = Column(CodingKeys.institution)
        public static let completed = Column(CodingKeys.completed)
        public static let updatedAt = Column(CodingKeys.updatedAt)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
