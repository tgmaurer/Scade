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

    /// The widest the card may be drawn, whatever the window does.
    ///
    /// `.infinity` — the default — lets it fill, which is right for a row
    /// that has something to put in the middle. See
    /// `ScadeDesign.maximumRowWidth` for when it isn't.
    let maximumWidth: Double

    @State private var isHovering = false

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            // The window margin, applied here rather than to the list — see
            // `groupedListStyle`. `CardRowSurface` insets the card behind it
            // by the same amount, so the two edges stay parallel.
            .padding(.horizontal, ScadeDesign.contentMargin)
            // Capped and then pushed to the leading edge, so the card lines
            // up with the window's title rather than drifting to the middle
            // as the window grows. The cap is applied *outside* the padding
            // so it bounds the card, margins included, at every width.
            .frame(maxWidth: maximumWidth + 2 * ScadeDesign.contentMargin, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Without this only the text is hoverable, so the highlight
            // flickers as the pointer crosses the gaps between columns.
            .contentShape(.rect)
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
                CardRowSurface(
                    position: position,
                    isHovering: isHovering,
                    maximumWidth: maximumWidth
                )
            )
        #else
        content
            .listRowSeparator(position.hasRowBelow ? .visible : .hidden)
            .listSectionSeparator(.hidden)
        #endif
    }
}
