import SwiftUI

/// One titled card on a detail screen (SPEC-POLISH §2.5).
///
/// **A detail screen is a document, not a list**, and this is what it's built
/// from instead of `List` rows. Three things follow from the distinction, and
/// the third is what forced it:
///
/// - There is nothing to swipe. `.swipeActions` is the reason iOS keeps a
///   `List` (§2.5); a detail screen's rows carry no actions, and its Delete
///   is in the toolbar.
/// - There is nothing to select or reorder, which is the rest of what a
///   `List` is for.
/// - **A macOS `List` swallows the drag that selects text.** Every `Text` in
///   one is inert however `.textSelection(.enabled)` is applied — on the
///   `Text`, on the row, or on the list itself; all three were tried and
///   measured. A detail screen is exactly where selecting text matters: an
///   institution's full name, a date, an average, a description worth pasting
///   somewhere else.
///
/// The card is drawn here rather than borrowed from `.insetGrouped`, so both
/// platforms get the same one instead of iOS getting the system's and macOS
/// assembling a lookalike.
///
/// **A function returning a `Section`, not a `View` of its own.** `DetailScroll`
/// pins section headers, and a `LazyVStack` pins only a `Section` it can *see*
/// — wrapped inside a custom `View`, the pinning silently does nothing at all
/// (built that way first, and the headers scrolled away as before). The same
/// constraint reaches one level up: whatever calls this has to be a
/// `@ViewBuilder` too, never a `View` struct holding sections.
///
/// It also carries its own margins, for the same reason: a pinned header has
/// to paint the full width of the scroll view, so the margin can't live on
/// the stack above or the content would scroll visibly through the gaps
/// either side of it.
func DetailSection<Content: View>(
    /// The header at the top of the card. Cards that need no title omit it —
    /// the identity card is the record itself, not a labelled part of it.
    title: LocalizedStringKey? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    Section {
        DetailCard(isTitled: title != nil, content: content)
    } header: {
        DetailSectionHeader(title: title)
    }
}

/// The rounded surface a section's rows sit on.
struct DetailCard<Content: View>: View {
    /// Whether a header sits directly above. Its card is the same card, so
    /// this one gives up its top corners rather than starting a second shape
    /// a hairline below the first.
    var isTitled = false

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(.background.secondary))
        .padding(.horizontal, ScadeDesign.contentMargin)
        // The gap to whatever comes next. Carried here rather than as the
        // stack's spacing, for the same reason as the margin.
        .padding(.bottom, ScadeDesign.contentMargin)
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isTitled ? 0 : ScadeDesign.cardCornerRadius,
            bottomLeadingRadius: ScadeDesign.cardCornerRadius,
            bottomTrailingRadius: ScadeDesign.cardCornerRadius,
            topTrailingRadius: isTitled ? 0 : ScadeDesign.cardCornerRadius
        )
    }
}

/// A section's title — the top of its card, and pinned there while the rows
/// below scroll past underneath.
///
/// **It sits on the card rather than above it**, which is the second attempt.
/// A label floating in the gap between two cards belongs to neither, and at
/// 1× a line of small secondary text with space above and below reads as a
/// stripe rather than as a heading. On the card it is unambiguously the
/// heading *of that card*, it has a divider under it doing the work the gap
/// was failing to do, and when it pins, what stays behind is the card's own
/// top edge instead of an opaque band cutting across the rows.
///
/// It borrows `CardRowSurface` for all of that, so the shape, the fill, the
/// divider and the window margin are the ones every other card row uses.
struct DetailSectionHeader: View {
    let title: LocalizedStringKey?

    var body: some View {
        if let title {
            Text(title)
                .font(ScadeDesign.rowSecondary)
                .bold()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScadeDesign.contentMargin + ScadeDesign.cardTilePadding)
                .padding(.vertical, ScadeDesign.cardTilePadding)
                .background(
                    CardRowSurface(
                        position: .first,
                        isHovering: false,
                        margin: ScadeDesign.contentMargin
                    )
                )
        }
    }
}

/// A block of text as a card's whole content — a description, or a "nothing
/// here yet" line.
struct DetailSectionText<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ScadeDesign.cardTilePadding)
    }
}
