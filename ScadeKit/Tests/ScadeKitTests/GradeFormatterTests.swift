import Foundation
import Testing

@testable import ScadeKit

/// Pinned to a fixed locale: half of Europe writes `5,25`, and a test that
/// assumed a decimal point would pass here and fail on a Swiss machine.
@Suite("GradeFormatter (§3.3)")
struct GradeFormatterTests {
    let formatter = GradeFormatter(locale: Locale(identifier: "en_US_POSIX"))

    @Test("Prints grade values with exactly two decimals")
    func formatsValues() {
        #expect(formatter.value(5.0) == "5.00")
        #expect(formatter.value(5.25) == "5.25")
        #expect(formatter.value(4.5) == "4.50")
        #expect(formatter.value(1.0) == "1.00")
    }

    /// Rounding happens at display time only; the stored value keeps whatever
    /// the user entered (§3.3).
    @Test("Rounds for display without touching the value")
    func roundsForDisplay() {
        #expect(formatter.value(5.256) == "5.26")
        #expect(formatter.value(8.0 / 1.5) == "5.33")
        #expect(formatter.value(5.0 / 3.0) == "1.67")
    }

    @Test("Prints N/A when there is no average yet")
    func formatsMissingAverage() {
        #expect(formatter.average(nil) == "N/A")
        #expect(formatter.average(nil) == GradeFormatter.noDataPlaceholder)
    }

    @Test("Prints an average the same way as a grade value")
    func formatsAverage() {
        #expect(formatter.average(5.25) == "5.25")
        #expect(formatter.average(8.0 / 1.5) == "5.33")
    }

    /// Storage keeps the multiplier; only the display is a percentage.
    @Test("Prints weights as percentages")
    func formatsWeights() {
        #expect(formatter.weight(1.0) == "100%")
        #expect(formatter.weight(0.5) == "50%")
        #expect(formatter.weight(1.25) == "125%")
        #expect(formatter.weight(3.0) == "300%")
    }

    @Test("Keeps one decimal for the fractional quick-picks")
    func formatsFractionalWeights() {
        #expect(formatter.weight(0.625) == "62.5%")
        #expect(formatter.weight(0.375) == "37.5%")
        #expect(formatter.weight(0.125) == "12.5%")
        #expect(formatter.weight(0.667) == "66.7%")
        #expect(formatter.weight(0.333) == "33.3%")
    }

    @Test("Follows the locale it was given")
    func respectsLocale() {
        let swiss = GradeFormatter(locale: Locale(identifier: "de_CH"))

        #expect(swiss.value(5.25).contains("5"))
        #expect(swiss.value(5.25).contains("25"))
    }
}
