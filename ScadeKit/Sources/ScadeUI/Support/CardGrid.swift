import SwiftUI

/// A grid of card tiles that answers the width it's given (SPEC-POLISH §2.5,
/// §2.6).
///
/// Written for a collection short enough to be taken in at once. A single
/// column of educations in a wide window is the "content stranded in a wide
/// window" finding in §0.1 at its plainest: there are a handful of them, each
/// a substantial object, and nothing to scroll past to reach the rest — so
/// the window is mostly empty and the list is still not all visible on a
/// small one.
///
/// **All three macOS list screens use it now, and only educations were
/// argued into it.** Subjects and then grades took it as deliberate
/// overrides of the §2.5 test, on preference, each recorded there with what
/// it costs — a grid of hundreds of grades is the case that test warns
/// about. Read that section before extending this to a fourth screen: the
/// rule is still cardinality, and three exceptions in a row is what a rule
/// quietly becoming a habit looks like.
struct CardGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        GeometryReader { proxy in
            // The width the grid lays itself out for, which is not always the
            // width it's been given: past the cap the columns are sized for
            // the cap, or they'd be computed for a window they aren't going
            // to fill.
            let width = min(proxy.size.width, ScadeDesign.cardGridMaximumWidth)

            ScrollView {
                LazyVGrid(
                    columns: Self.columns(forWidth: width, itemCount: items.count),
                    alignment: .leading,
                    spacing: ScadeDesign.cardGridSpacing
                ) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                // On the content, not on the scroll view. Padding the scroll
                // view shrinks its whole frame and takes the scroller with
                // it, leaving the scrollbar floating short of the window edge
                // instead of sitting on it.
                .padding(ScadeDesign.contentMargin)
                // Two frames: the first caps the content, the second fills
                // the window so the first is centred inside it. The scroll
                // view itself stays full width, so the scroller stays on the
                // window edge where it belongs.
                .frame(maxWidth: ScadeDesign.cardGridMaximumWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private static func columns(forWidth width: Double, itemCount: Int) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: ScadeDesign.cardGridSpacing),
            count: columnCount(forWidth: width, itemCount: itemCount)
        )
    }

    /// How many columns fit — never more than the ceiling, and never more
    /// than there are items to fill them.
    ///
    /// Capped by the item count as well as the width because a grid with
    /// holes in its only row doesn't read as a full grid: two tiles in three
    /// columns look like a third one failed to load. With the cap, two
    /// educations are two columns and each gets half the window.
    ///
    /// Internal and static so the arithmetic can be tested directly. It's the
    /// part that has an off-by-one in it, and the part `ImageRenderer` can't
    /// reach — a `LazyVGrid` inside a `ScrollView` renders no more headlessly
    /// than a `List` does.
    static func columnCount(forWidth width: Double, itemCount: Int) -> Int {
        guard itemCount > 0, width.isFinite else { return 1 }

        // The trailing gap is the one a column doesn't need: n columns have
        // n - 1 gaps between them, so lending the width one extra gap makes
        // the division come out even.
        let usable = max(0, width - 2 * ScadeDesign.contentMargin) + ScadeDesign.cardGridSpacing
        let stride = ScadeDesign.minimumCardWidth + ScadeDesign.cardGridSpacing
        let fits = Int(usable / stride)

        return max(1, min(fits, ScadeDesign.maximumCardColumns, itemCount))
    }
}
