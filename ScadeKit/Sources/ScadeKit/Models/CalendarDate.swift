import Foundation
import GRDB

/// A single day on the Gregorian calendar, with no time and no time zone.
///
/// The schema (SPEC §2) declares `Educations.startDate`, `Educations.endDate`
/// and `Grades.date` as date-only `yyyy-MM-dd` text. Modelling those as `Date`
/// would drag a time-of-day and a time zone into every comparison, so
/// `endDate >= startDate` and the grade-within-education-range rule (§3.4)
/// would start depending on where the user happens to be standing.
/// `CalendarDate` has no component that can drift.
///
/// The zero-padded `yyyy-MM-dd` form also sorts lexicographically in
/// chronological order, which is what makes the SQL `CHECK (endDate >=
/// startDate)` constraint and `ORDER BY date DESC` (§3.6) correct on the raw
/// stored text.
public struct CalendarDate: Hashable, Sendable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Gregorian calendar fixed to GMT, used only to answer "is this a real
    /// day?" and to do day arithmetic. Deliberately not the user's calendar:
    /// the answer must not vary by locale or region.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Creates a date, or returns `nil` if the components don't form a real
    /// day (30 February, month 13, day 0, …).
    public init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        guard components.isValidDate(in: Self.calendar) else { return nil }

        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses the fixed `yyyy-MM-dd` storage format.
    ///
    /// Hand-parsed rather than run through a `DateFormatter` because this is
    /// data exchange with SQLite, not user-facing display: no locale,
    /// calendar or time zone may influence the result.
    public init?(iso8601 text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }

        self.init(year: year, month: month, day: day)
    }

    /// The calendar day `date` falls on, in the given time zone.
    public init(_ date: Date, in timeZone: TimeZone = .autoupdatingCurrent) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        // A date always yields valid components, so the failable initializer
        // cannot fail here.
        self.year = components.year ?? 1
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    public static func today(in timeZone: TimeZone = .autoupdatingCurrent) -> CalendarDate {
        CalendarDate(.now, in: timeZone)
    }

    /// The `yyyy-MM-dd` storage representation.
    public var iso8601String: String {
        "\(Self.padded(year, width: 4))-\(Self.padded(month, width: 2))-\(Self.padded(day, width: 2))"
    }

    /// Midnight on this day, in the given time zone.
    public func startOfDay(in timeZone: TimeZone = .autoupdatingCurrent) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? .now
    }

    /// Shifts the date by whole calendar units. Returns `self` unchanged if
    /// the shift somehow lands outside the representable calendar.
    public func adding(years: Int = 0, months: Int = 0, days: Int = 0) -> CalendarDate {
        let components = DateComponents(year: year, month: month, day: day)
        guard let base = Self.calendar.date(from: components),
              let shifted = Self.calendar.date(
                  byAdding: DateComponents(year: years, month: months, day: days),
                  to: base
              )
        else { return self }

        return CalendarDate(shifted, in: .gmt)
    }

    public static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func padded(_ value: Int, width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}

extension CalendarDate: CustomStringConvertible {
    public var description: String { iso8601String }
}

extension CalendarDate: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let date = CalendarDate(iso8601: text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "'\(text)' is not a yyyy-MM-dd calendar date"
            )
        }
        self = date
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }
}

extension CalendarDate: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { iso8601String.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> CalendarDate? {
        guard let text = String.fromDatabaseValue(dbValue) else { return nil }
        return CalendarDate(iso8601: text)
    }
}
