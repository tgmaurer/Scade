import Testing

@testable import ScadeKit

@Suite("AcademicYear")
struct AcademicYearTests {

    @Test("Runs 1 August to 31 July of the following year")
    func spansAugustToJuly() {
        let year = AcademicYear.starting(in: 2026)

        #expect(year.lowerBound == CalendarDate.iso("2026-08-01"))
        #expect(year.upperBound == CalendarDate.iso("2027-07-31"))
    }

    @Test("Before August, belongs to the year already running")
    func rollsBackBeforeAugust() {
        let march = AcademicYear.containing(CalendarDate.iso("2026-03-14"))

        #expect(march.lowerBound == CalendarDate.iso("2025-08-01"))
        #expect(march.upperBound == CalendarDate.iso("2026-07-31"))
    }

    @Test("From August onwards, belongs to the year just started")
    func rollsForwardFromAugust() {
        let august = AcademicYear.containing(CalendarDate.iso("2026-08-01"))

        #expect(august.lowerBound == CalendarDate.iso("2026-08-01"))
        #expect(august.upperBound == CalendarDate.iso("2027-07-31"))
    }

    /// The property the create form depends on: a new education always spans
    /// today, so a grade dated today (§4's default) is inside its range and
    /// passes the §3.4 date check.
    @Test(
        "Always contains the date it was asked about",
        arguments: [
            "2026-01-01", "2026-07-31", "2026-08-01", "2026-12-31",
            "2024-02-29", "2027-06-15",
        ]
    )
    func containsItsOwnDate(iso: String) {
        let date = CalendarDate.iso(iso)

        #expect(AcademicYear.containing(date).contains(date))
    }

    @Test("Ends the day before the next year starts")
    func abutsTheFollowingYear() {
        let first = AcademicYear.starting(in: 2026)
        let next = AcademicYear.starting(in: 2027)

        #expect(first.upperBound.adding(days: 1) == next.lowerBound)
    }

    @Test("Produces a range the education validator accepts")
    func satisfiesValidation() {
        let year = AcademicYear.starting(in: 2026)
        let education = Education(
            name: "Informatik",
            description: nil,
            semesters: 2,
            startDate: year.lowerBound,
            endDate: year.upperBound,
            institution: nil,
            completed: false
        )

        #expect(EducationValidator.validate(education).isEmpty)
    }

    @Test("Holds across a leap year", arguments: [2023, 2024, 2027, 2100])
    func handlesLeapYears(year: Int) {
        let range = AcademicYear.starting(in: year)

        #expect(range.lowerBound.month == 8 && range.lowerBound.day == 1)
        #expect(range.upperBound.month == 7 && range.upperBound.day == 31)
        #expect(range.upperBound.year == year + 1)
    }
}
