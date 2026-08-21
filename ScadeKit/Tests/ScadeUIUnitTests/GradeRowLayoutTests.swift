#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The grade tile is the same height whatever is written in it.
///
/// A grid row is as tall as the tallest tile in it, so a tile that grows a
/// line leaves dead space under every grade beside it. The pressure is worse
/// here than on the other two grids: a description runs to
/// `maximumDescriptionLength`, ten times a name's cap, and it sits in the
/// slot a name occupies elsewhere.
@MainActor
struct GradeRowLayoutTests {
    /// The narrowest a tile is ever laid out at, less its own padding — the
    /// grid holds to `minimumCardWidth`, so a tile that fits here fits
    /// everywhere.
    private let narrowest = ScadeDesign.minimumCardWidth - 2 * ScadeDesign.cardTilePadding

    private func height(
        _ item: GradeListItem,
        width: Double,
        showsContext: Bool = true
    ) throws -> Double {
        let renderer = ImageRenderer(
            content: GradeRowView(item: item, showsContext: showsContext).frame(width: width)
        )
        return try #require(renderer.nsImage).size.height
    }

    private var plain: GradeListItem { PreviewData.gradeItem() }

    // MARK: - The heading

    /// The description heads the tile and is held to a single line.
    ///
    /// One, where the education and subject tiles give their *names* two. A
    /// description is a note rather than a name: it runs to 2500 characters,
    /// it is often absent, and on a grid every extra line is paid for by
    /// every tile in the row.
    @Test func aDescriptionIsHeldToOneLine() throws {
        let short = PreviewData.gradeItem(details: "Vortrag")
        let wordy = PreviewData.gradeItem(details: String(repeating: "Wide ", count: 12))
        let far = PreviewData.gradeItem(
            details: String(repeating: "a", count: ValidationLimits.maximumDescriptionLength)
        )

        #expect(try height(wordy, width: narrowest) == height(short, width: narrowest))
        #expect(try height(far, width: narrowest) == height(short, width: narrowest))
    }

    /// The fallback, stated directly.
    ///
    /// Asserted on the property and not on a render, because a render cannot
    /// see it: "Schlussprüfung" and "Analysis" are both one line at the same
    /// size, so every height in this suite is identical whichever heads the
    /// tile. Measured that way, dropping the fallback altogether looked like
    /// a passing test — and now that the heading is bounded to one line,
    /// there is no long-name trick left to catch it either.
    @Test func theSubjectHeadsATileThatHasNoDescriptionOfItsOwn() {
        let described = GradeRowView(item: PreviewData.gradeItem(details: "Schlussprüfung"))
        #expect(described.heading == "Schlussprüfung")
        #expect(described.showsSubject)

        let bare = GradeRowView(item: PreviewData.gradeItem(details: nil))
        #expect(bare.heading == "Analysis")
        // Promoted, not repeated.
        #expect(bare.showsSubject == false)
    }

    /// An empty string is not a description, and must not head a tile as one.
    @Test func anEmptyDescriptionIsTreatedAsNone() {
        #expect(GradeRowView(item: PreviewData.gradeItem(details: "")).heading == "Analysis")
    }

    /// Under a subject there is no fallback to make: the screen already says
    /// which subject this is, so an undescribed grade has nothing to head it
    /// and the value leads instead.
    @Test func aGradeUnderItsSubjectFallsBackToNothing() {
        let bare = GradeRowView(item: PreviewData.gradeItem(details: nil), showsContext: false)

        #expect(bare.heading == nil)
    }

    /// And the fallback costs no height of its own: promoting the subject
    /// takes it off the context line, so the tile stays the same three
    /// blocks it was.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aGradeWithoutADescriptionIsTheSameHeight(width: Double) throws {
        let none = PreviewData.gradeItem(details: nil)

        #expect(try height(none, width: width) == height(plain, width: width))
    }

    // MARK: - The context line

    /// The parent education is held to one line however long its name — it's
    /// the half of the context line worth losing, since it repeats down the
    /// whole list.
    @Test func aVeryLongEducationNameDoesNotMakeTheTileTaller() throws {
        var item = plain
        item.education = PreviewData.education(
            name: String(repeating: "b", count: ValidationLimits.maximumNameLength)
        )

        #expect(try height(item, width: narrowest) == height(plain, width: narrowest))
    }

    /// And so is the subject beside it, which is unbounded too — pinning it
    /// outright would have let a long one push the education onto its own
    /// line rather than truncate.
    @Test func aVeryLongSubjectNameDoesNotMakeTheTileTaller() throws {
        var item = plain
        item.subject.name = String(repeating: "c", count: ValidationLimits.maximumNameLength)

        #expect(try height(item, width: narrowest) == height(plain, width: narrowest))
    }

    // MARK: - The meta line

    /// The weight only appears when it isn't the default, so the bottom line
    /// has one more thing in it sometimes.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aWeightedGradeIsTheSameHeight(width: Double) throws {
        let weighted = PreviewData.gradeItem(weight: 0.5)

        #expect(try height(weighted, width: width) == height(plain, width: width))
    }

    // MARK: - Under a subject

    /// The subject detail knows its own subject and education, so the context
    /// line goes — and the tile is a line shorter, not a line of blank.
    @Test func hidingTheContextTakesTheLineWithIt() throws {
        let withContext = try height(plain, width: narrowest)
        let without = try height(plain, width: narrowest, showsContext: false)

        #expect(without < withContext)
    }

    /// Under its subject a grade with no description is one line: the date
    /// and the value, with nothing under them.
    @Test func aGradeWithNothingToNameItIsOneLine() throws {
        let bare = PreviewData.gradeItem(details: nil)
        let named = PreviewData.gradeItem(details: "Schlussprüfung")

        #expect(
            try height(bare, width: narrowest, showsContext: false)
                < height(named, width: narrowest, showsContext: false)
        )
    }

    /// And its value still sits at the trailing edge.
    ///
    /// The one thing a height cannot see, and the thing that was wrong: the
    /// value used to *lead* that line, which reads fine on a tile standing
    /// alone and badly in a column of grades under one subject — some values
    /// hard left, some hard right, no column to run the eye down.
    @Test func theValueKeepsTheTrailingEdgeWithNothingToNameIt() throws {
        let bare = GradeRowView(item: PreviewData.gradeItem(details: nil), showsContext: false)
        let natural = try height(PreviewData.gradeItem(details: nil), width: narrowest, showsContext: false)

        #expect(
            try RenderedInk.hasInk(
                of: bare,
                width: narrowest,
                height: natural,
                in: CGRect(x: 0.75, y: 0, width: 0.25, height: 1)
            ),
            "The value should be drawn in the trailing quarter of the row."
        )
    }

    /// Under its subject the description is a note beneath the date, held to
    /// one line however long it runs.
    ///
    /// The pair of assertions is the point: a description costs exactly one
    /// line, and costs exactly one line whatever is in it. Rows are one line
    /// or two, never three, so a column of them keeps its rhythm.
    @Test func aDescriptionUnderASubjectCostsExactlyOneLine() throws {
        let bare = try height(PreviewData.gradeItem(details: nil), width: 600, showsContext: false)
        let short = try height(
            PreviewData.gradeItem(details: "Vortrag"), width: 600, showsContext: false
        )
        let far = try height(
            PreviewData.gradeItem(
                details: String(repeating: "a", count: ValidationLimits.maximumDescriptionLength)
            ),
            width: 600,
            showsContext: false
        )

        #expect(short > bare)
        #expect(far == short)
    }

    // MARK: - Bottom alignment

    /// Given more height than it needs, the tile spreads rather than sitting
    /// at the top of it — so the dates and weights land on one line across a
    /// whole grid row.
    @Test func theTileReachesTheBottomOfATallerFrameThanItNeeds() throws {
        let natural = try height(plain, width: narrowest)

        #expect(
            try RenderedInk.reachesBottom(
                of: GradeRowView(item: plain),
                width: narrowest,
                height: natural * 2
            )
        )
    }
}
#endif
