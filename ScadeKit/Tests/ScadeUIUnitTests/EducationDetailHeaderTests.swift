#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The education detail's identity card grows to fit what's in it.
///
/// The opposite discipline to the tile tests: a tile is bounded because a grid
/// row is as tall as its tallest member, and this card has no neighbour to
/// drag. Here the mistake would be to copy the tiles' `.lineLimit`s across —
/// a detail screen is where the full institution and the exact dates live,
/// and a truncated date is a half-written fact.
@MainActor
struct EducationDetailHeaderTests {
    /// Longer than any window is wide, so this measures the bound and not
    /// the width. A real one — "gibb, Gewerblich Industrielle Berufsfachschule
    /// Bern" — fits on one line at every width the app actually runs at,
    /// which is why the tiles' one-line rule was invisible here.
    private let longInstitution = String(repeating: "Berufsfachschule ", count: 15)

    /// Wide enough for the date range on one line — the case the fallback
    /// below is measured against.
    private let wide = 600.0

    private func header(institution: String? = "ETH", average: Double? = 4.92) -> EducationDetailHeader {
        var education = Education(
            name: "Informatiker EFZ",
            description: nil,
            semesters: 8,
            startDate: .today(),
            endDate: .today().adding(years: 4),
            institution: institution
        )
        education.id = 1

        return EducationDetailHeader(
            summary: EducationSummary(education: education, subjects: []),
            average: average
        )
    }

    private func height(_ content: some View, width: Double) throws -> Double {
        let renderer = ImageRenderer(content: content.frame(width: width))
        return try #require(renderer.nsImage).size.height
    }

    /// The institution is printed in full, wrapping if it must.
    ///
    /// The tiles hold it to one line because a grid row is as tall as its
    /// tallest tile. Nothing here is beside it, so the reason doesn't carry
    /// over — and this is the screen you open *to* read the whole name.
    @Test func aLongInstitutionWrapsRatherThanTruncating() throws {
        let long = try height(header(institution: longInstitution), width: wide)
        let short = try height(header(institution: "ETH"), width: wide)

        #expect(long > short)
    }

    /// And an education with none is shorter still, rather than leaving a
    /// blank line where one would have gone.
    @Test func anEducationWithNoInstitutionIsShorter() throws {
        let none = try height(header(institution: nil), width: wide)
        let some = try height(header(institution: "ETH"), width: wide)

        #expect(none < some)
    }

    /// An empty string is not an institution.
    @Test func anEmptyInstitutionIsTreatedAsNone() throws {
        let empty = try height(header(institution: ""), width: wide)
        let none = try height(header(institution: nil), width: wide)

        #expect(empty == none)
    }

    /// Squeezed, the date range wraps onto two lines instead of truncating.
    ///
    /// "Aug 1, 2023 – Jul…" is not a date range, and a truncated end date is
    /// the half of it you opened the screen for. Reachable on a phone at an
    /// accessibility text size, not on a Mac — the app's minimum window is
    /// far wider than this.
    @Test func theDateRangeWrapsRatherThanTruncating() throws {
        // The range on its own, not the header around it. Everything else on
        // the card wraps as the width drops as well, so a whole-header
        // measurement is taller at a narrow width either way.
        let narrow = try height(header().dateRange, width: 90)
        let roomy = try height(header().dateRange, width: wide)

        #expect(narrow > roomy)
    }
}
#endif
