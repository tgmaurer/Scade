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

    @State private var isHovering = false

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            // Without this only the text is hoverable, so the highlight
            // flickers as the pointer crosses the gaps between columns.
            .contentShape(.rect)
            .onHover { isHovering = $0 }
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
}
