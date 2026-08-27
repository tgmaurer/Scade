import SwiftUI
import Testing
@testable import ScadeUI

/// The card grid's column arithmetic.
///
/// Worth testing directly because it's the one part of the grid with an
/// off-by-one in it, and the one part nothing else can check: a `LazyVGrid`
/// inside a `ScrollView` renders no more headlessly than a `List` does, so
/// `ImageRenderer` can't reach the laid-out result.
@MainActor
struct CardGridTests {
    private typealias Grid = CardGrid<PreviewRow, EmptyView>

    /// Stands in for whatever the grid is holding — only the count matters.
    private struct PreviewRow: Identifiable {
        let id: Int
    }

    private func columns(width: Double, items: Int = 100) -> Int {
        Grid.columnCount(forWidth: width, itemCount: items)
    }

    /// The window's own margins come off the top before anything is divided.
    private var overhead: Double { 2 * ScadeDesign.contentMargin }

    @Test func oneTileWideGivesOneColumn() {
        #expect(columns(width: overhead + ScadeDesign.minimumCardWidth) == 1)
    }

    /// The gap between two columns has to be paid for, so a window exactly
    /// two minimum tiles wide is still a one-column window.
    @Test func twoTilesWithNoRoomForTheGapStaysOneColumn() {
        #expect(columns(width: overhead + 2 * ScadeDesign.minimumCardWidth) == 1)
    }

    @Test func twoTilesPlusTheGapGivesTwoColumns() {
        let width = overhead + 2 * ScadeDesign.minimumCardWidth + ScadeDesign.cardGridSpacing

        #expect(columns(width: width) == 2)
    }

    @Test func threeTilesPlusTheirGapsGivesThreeColumns() {
        let width = overhead + 3 * ScadeDesign.minimumCardWidth + 2 * ScadeDesign.cardGridSpacing

        #expect(columns(width: width) == 3)
    }

    /// However wide the window, the grid stops at the ceiling — otherwise a
    /// full-screen display turns a short list into a field of boxes.
    @Test func aVeryWideWindowStopsAtTheCeiling() {
        #expect(columns(width: 6000) == ScadeDesign.maximumCardColumns)
    }

    /// Fewer items than columns would leave holes in the only row, which
    /// reads as a tile that failed to load rather than as a full grid.
    @Test func theGridIsNeverWiderThanItHasItemsToFill() {
        #expect(columns(width: 6000, items: 2) == 2)
        #expect(columns(width: 6000, items: 1) == 1)
    }

    /// A `GeometryReader` reports zero on its first pass, and `Int(_:)` traps
    /// on a value it can't represent — so the degenerate widths are the ones
    /// that would crash rather than merely look wrong.
    @Test(arguments: [0.0, -500.0, .infinity, .nan] as [Double])
    func degenerateWidthsFallBackToOneColumn(width: Double) {
        #expect(columns(width: width) == 1)
    }

    @Test func anEmptyGridStillAsksForOneColumn() {
        #expect(columns(width: 6000, items: 0) == 1)
    }
}
