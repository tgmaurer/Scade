import SwiftUI

/// A row of a card: its surface, its hover state, and the line to the row
/// below it (SPEC-POLISH §2.5).
///
/// macOS only in effect. iOS's `.insetGrouped` list already draws the card and
/// insets its own separators correctly, so there it does nothing but take the
/// redundant separators away.
///
/// A `ViewModifier` rather than a `View` extension because hover is state, and
/// an extension has nowhere to keep it.
struct CardRow: ViewModifier {
    let position: CardRowPosition

    /// Whether the row itself answers the pointer.
    ///
    /// Off for a row that isn't a way through to anything — the summary
    /// header is a card of figures with one button in it, and lighting the
    /// whole card up promises a click that does nothing.
    let highlightsOnHover: Bool

    @State private var isHovering = false

    func body(content: Content) -> some View {
        #if os(macOS)
        hoverable(content)
            .onHover { isHovering = highlightsOnHover && $0 }
            // Every system separator is off, and the card draws its own
            // instead. The list's are the "too many horizontal lines" problem
            // in miniature: it rules a line above the first row and below the
            // last, where there is nothing on the other side to separate
            // from, and runs them the full width of the list rather than
            // stopping at the card they belong to.
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowBackground(
                CardRowSurface(position: position, isHovering: isHovering)
            )
        #else
        content
            .listRowSeparator(position.hasRowBelow ? .visible : .hidden)
            .listSectionSeparator(.hidden)
        #endif
    }

    /// The row, at the window margin, and hit-testable as a whole *only*
    /// where it answers the pointer.
    ///
    /// The margin is applied here rather than to the list — see
    /// `groupedListStyle`. `CardRowSurface` insets the card behind it by the
    /// same amount, so the two edges stay parallel.
    ///
    /// `contentShape` is what stops the hover highlight flickering as the
    /// pointer crosses the gaps between columns. It is a hit-test shape as
    /// well, though, so on a card that doesn't hover it buys nothing and
    /// costs the drag that selects text — which is what left
    /// `.textSelection(.enabled)` on the education detail's header card
    /// doing nothing at all.
    @ViewBuilder
    private func hoverable(_ content: Content) -> some View {
        let inset = content.padding(.horizontal, ScadeDesign.contentMargin)

        if highlightsOnHover {
            inset.contentShape(.rect)
        } else {
            inset
        }
    }
}
