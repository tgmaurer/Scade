#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The education tile is the same height whatever is written in it.
///
/// A grid row is as tall as the tallest tile in it, so a tile that grows a
/// line doesn't only look wrong itself — it leaves dead space under every
/// other education beside it. That's what a wrapping institution did, and
/// it's invisible to every flow test: the app built, launched, and drew all
/// the right words.
///
/// Measured with `ImageRenderer`, which gives a real layout pass without a
/// window. It measures the row alone; the grid around it is a `LazyVGrid` in
/// a `ScrollView` and renders no more headlessly than a `List` does — see
/// `CardGridTests` for the part of the grid that *is* reachable.
@MainActor
struct EducationRowLayoutTests {
    /// Long enough to overflow a tile at any column count — this is a real
    /// institution name, and the one in the screenshot that wrapped.
    private let longInstitution = "gibb, Gewerblich Industrielle Berufsfachschule Bern"

    /// The narrowest a tile is ever laid out at, less its own padding: the
    /// minimum card width is the floor the grid holds to, so a row that fits
    /// here fits everywhere.
    private let narrowest = ScadeDesign.minimumCardWidth - 2 * ScadeDesign.cardTilePadding

    private func row(institution: String?) -> EducationRow {
        var education = Education(
            name: "Informatiker EFZ",
            description: nil,
            semesters: 8,
            startDate: .today(),
            endDate: .today().adding(years: 4),
            institution: institution
        )
        education.id = 1

        return EducationRow(EducationSummary(education: education, subjects: []))
    }

    private func height(institution: String?, width: Double) throws -> Double {
        let renderer = ImageRenderer(
            content: EducationRowView(row: row(institution: institution)).frame(width: width)
        )
        return try #require(renderer.nsImage).size.height
    }

    /// The fix, stated directly: however long the institution, the tile is
    /// the height of the one beside it.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aLongInstitutionDoesNotMakeTheRowTaller(width: Double) throws {
        let long = try height(institution: longInstitution, width: width - 2 * ScadeDesign.cardTilePadding)
        let short = try height(institution: "ETH", width: width - 2 * ScadeDesign.cardTilePadding)

        #expect(long == short)
    }

    /// And an education with no institution at all matches too — that row
    /// takes a different branch, so it could drift on its own.
    @Test func anEducationWithNoInstitutionIsTheSameHeight() throws {
        let none = try height(institution: nil, width: narrowest)
        let some = try height(institution: "ETH", width: narrowest)

        #expect(none == some)
    }

    /// An empty string is not an institution, and must not render as one with
    /// a separator hanging off it.
    @Test func anEmptyInstitutionIsTreatedAsNone() throws {
        let empty = try height(institution: "", width: narrowest)
        let none = try height(institution: nil, width: narrowest)

        #expect(empty == none)
    }
}
#endif
