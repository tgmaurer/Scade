#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The subject tile is the same height whatever is written in it.
///
/// A grid row is as tall as the tallest tile in it, so a tile that grows a
/// line leaves dead space under every subject beside it. Measured by
/// rendering, which is the only way to see it: all of these draw the right
/// words and pass every flow test.
@MainActor
struct SubjectRowLayoutTests {
    /// The narrowest a tile is ever laid out at, less its own padding — the
    /// grid holds to `minimumCardWidth`, so a tile that fits here fits
    /// everywhere.
    private let narrowest = ScadeDesign.minimumCardWidth - 2 * ScadeDesign.cardTilePadding

    private func height(_ row: SubjectRow, width: Double) throws -> Double {
        let renderer = ImageRenderer(content: SubjectRowView(row: row).frame(width: width))
        return try #require(renderer.nsImage).size.height
    }

    private var plain: SubjectRow { PreviewData.subjectRow(name: "Analysis") }

    /// A subject with no grades has no average, and "N/A" is a different
    /// width from "4.50" — it must not be a different height.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aSubjectWithoutGradesIsTheSameHeight(width: Double) throws {
        let none = PreviewData.subjectRow(name: "Analysis", grades: [])

        #expect(try height(none, width: width) == height(plain, width: width))
    }

    /// The weight only appears when it isn't the default, so the tile has one
    /// more thing in it sometimes.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aWeightedSubjectIsTheSameHeight(width: Double) throws {
        let weighted = PreviewData.subjectRow(name: "Analysis", weight: 1.5)

        #expect(try height(weighted, width: width) == height(plain, width: width))
    }

    /// And completing one swaps its badge for a wider one.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aCompletedSubjectIsTheSameHeight(width: Double) throws {
        let completed = PreviewData.subjectRow(name: "Analysis", completed: true)

        #expect(try height(completed, width: width) == height(plain, width: width))
    }

    /// The name wraps once and then stops — bounded for the same reason an
    /// education's is, since names run to 255 characters.
    @Test func aNameLongerThanTwoLinesIsNoTallerThanTwoLines() throws {
        let twoLines = PreviewData.subjectRow(name: String(repeating: "Wide ", count: 12))
        let far = PreviewData.subjectRow(
            name: String(repeating: "a", count: ValidationLimits.maximumNameLength)
        )

        #expect(try height(far, width: narrowest) == height(twoLines, width: narrowest))
    }

    /// The parent education is on the context line, which is held to one line
    /// however long that education's name is.
    @Test func aVeryLongEducationNameDoesNotMakeTheTileTaller() throws {
        var education = PreviewData.education(
            name: String(repeating: "b", count: ValidationLimits.maximumNameLength)
        )
        education.id = 1

        var subject = Subject(educationId: 1, name: "Analysis", semester: 3)
        subject.id = 1

        let long = SubjectRow(
            SubjectSummary(subject: subject, education: education, grades: [])
        )

        #expect(
            try height(long, width: narrowest)
                == height(PreviewData.subjectRow(name: "Analysis", grades: []), width: narrowest)
        )
    }

    /// Given more height than it needs, the tile spreads rather than sitting
    /// at the top of it — so the counts and status land on one line across a
    /// whole grid row.
    @Test func theTileReachesTheBottomOfATallerFrameThanItNeeds() throws {
        let natural = try height(plain, width: narrowest)

        #expect(
            try RenderedInk.reachesBottom(
                of: SubjectRowView(row: plain),
                width: narrowest,
                height: natural * 2
            )
        )
    }
}
#endif
