import Foundation

/// The school year an education is assumed to run over.
///
/// Only a *default* — nothing validates against it and nothing stops an
/// education spanning any range the user likes (§3.4 only requires
/// `endDate >= startDate`). It exists so the create form opens on the dates
/// someone is overwhelmingly likely to want, rather than on today's date and
/// an arbitrary year from now.
///
/// Lives here rather than in the form because it's a rule about the domain,
/// not about a text field, and because a rule that decides what a user's data
/// starts out as is worth a test.
public enum AcademicYear {
    /// 1 August — the conventional start of the Swiss school year.
    public static let startMonth = 8
    public static let startDay = 1

    /// 31 July, the day before the next one begins.
    public static let endMonth = 7
    public static let endDay = 31

    /// The academic year `date` falls inside.
    ///
    /// Before August that's the year which began the *previous* August — a
    /// date in March belongs to the year already running, not the one about
    /// to start. Taking the calendar year instead would hand the create form
    /// a range that doesn't include today, and §3.4 requires a grade's date
    /// to sit within its education's range: every grade dated today would be
    /// rejected the moment the education was created, for the seven months
    /// from January to July.
    public static func containing(_ date: CalendarDate) -> ClosedRange<CalendarDate> {
        starting(in: date.month >= startMonth ? date.year : date.year - 1)
    }

    /// The academic year running from August of `year` to July of `year + 1`.
    public static func starting(in year: Int) -> ClosedRange<CalendarDate> {
        guard let start = CalendarDate(year: year, month: startMonth, day: startDay),
              let end = CalendarDate(year: year + 1, month: endMonth, day: endDay)
        else {
            // 1 August and 31 July exist in every year, so this is
            // unreachable — but it beats forcing an unwrap silently.
            preconditionFailure("The academic year bounds must be real dates.")
        }

        return start...end
    }
}
