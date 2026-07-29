import Foundation
import GRDB
import Testing

@testable import ScadeKit

@Suite("CalendarDate")
struct CalendarDateTests {

    @Test("Parses the yyyy-MM-dd storage format")
    func parsesStorageFormat() throws {
        let date = try #require(CalendarDate(iso8601: "2026-07-28"))

        #expect(date.year == 2026)
        #expect(date.month == 7)
        #expect(date.day == 28)
    }

    @Test(
        "Rejects anything that isn't a zero-padded yyyy-MM-dd date",
        arguments: [
            "2026-7-28",           // not zero-padded
            "26-07-28",            // short year
            "2026-13-01",          // no thirteenth month
            "2026-00-10",          // no zeroth month
            "2026-02-30",          // not a real day
            "2025-02-29",          // 2025 isn't a leap year
            "2026-07-28T00:00:00", // datetime, not a date
            "2026/07/28",
            "+026-07-28",          // Int() would happily take this
            "",
            "not-a-date",
        ]
    )
    func rejectsMalformedInput(text: String) {
        #expect(CalendarDate(iso8601: text) == nil)
    }

    @Test("Accepts a leap day in a leap year")
    func acceptsLeapDay() {
        #expect(CalendarDate(iso8601: "2024-02-29") != nil)
    }

    @Test("Round-trips through its string form")
    func roundTripsThroughString() throws {
        let date = CalendarDate.iso("2026-07-28")

        #expect(date.iso8601String == "2026-07-28")
        #expect(CalendarDate(iso8601: date.iso8601String) == date)
    }

    @Test("Pads single-digit months and days")
    func padsComponents() throws {
        let date = try #require(CalendarDate(year: 2026, month: 1, day: 5))

        #expect(date.iso8601String == "2026-01-05")
    }

    @Test("Orders chronologically")
    func ordersChronologically() {
        #expect(CalendarDate.iso("2025-12-31") < CalendarDate.iso("2026-01-01"))
        #expect(CalendarDate.iso("2026-01-31") < CalendarDate.iso("2026-02-01"))
        #expect(CalendarDate.iso("2026-01-01") < CalendarDate.iso("2026-01-02"))
        #expect(CalendarDate.iso("2026-01-01") == CalendarDate.iso("2026-01-01"))
    }

    /// The `CHECK (endDate >= startDate)` constraint and `ORDER BY date DESC`
    /// compare the stored text, so string order has to agree with date order.
    @Test("Sorts identically as text and as a date")
    func textOrderMatchesDateOrder() {
        let dates = [
            CalendarDate.iso("2026-01-02"),
            CalendarDate.iso("2025-12-31"),
            CalendarDate.iso("2026-01-10"),
            CalendarDate.iso("2026-02-01"),
            CalendarDate.iso("2024-06-15"),
        ]

        #expect(dates.sorted().map(\.iso8601String) == dates.map(\.iso8601String).sorted())
    }

    @Test("Adds calendar units")
    func addsCalendarUnits() {
        #expect(CalendarDate.iso("2026-07-28").adding(years: 1) == .iso("2027-07-28"))
        #expect(CalendarDate.iso("2026-01-31").adding(months: 1) == .iso("2026-02-28"))
        #expect(CalendarDate.iso("2026-12-31").adding(days: 1) == .iso("2027-01-01"))
        #expect(CalendarDate.iso("2024-02-28").adding(days: 1) == .iso("2024-02-29"))
    }

    @Test("Is independent of the time zone it is read in")
    func isTimeZoneIndependent() throws {
        // 23:30 in Zürich on 28 July is already 21:30 UTC the same day, but
        // 30 minutes later it is the 29th locally and still the 28th in UTC.
        let instant = try #require(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    timeZone: .gmt, year: 2026, month: 7, day: 28, hour: 23, minute: 30
                )
            )
        )

        #expect(CalendarDate(instant, in: .gmt) == .iso("2026-07-28"))
        #expect(
            CalendarDate(instant, in: TimeZone(identifier: "Europe/Zurich") ?? .gmt)
                == .iso("2026-07-29")
        )
    }

    @Test("Round-trips through Codable")
    func roundTripsThroughCodable() throws {
        let date = CalendarDate.iso("2026-07-28")
        let encoded = try JSONEncoder().encode(date)

        #expect(String(decoding: encoded, as: UTF8.self) == "\"2026-07-28\"")
        #expect(try JSONDecoder().decode(CalendarDate.self, from: encoded) == date)
    }

    @Test("Round-trips through a database value as text")
    func roundTripsThroughDatabaseValue() {
        let date = CalendarDate.iso("2026-07-28")

        #expect(date.databaseValue == "2026-07-28".databaseValue)
        #expect(CalendarDate.fromDatabaseValue(date.databaseValue) == date)
        #expect(CalendarDate.fromDatabaseValue("2026-13-01".databaseValue) == nil)
        #expect(CalendarDate.fromDatabaseValue(42.databaseValue) == nil)
    }
}
