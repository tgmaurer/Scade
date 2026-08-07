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
            // instead. The list's are the "too many horizontal lines"
            // problem in miniature: it rules a line above the first row and
            // below the last, where there is nothing on the other side to
            // separate from, and runs them the full width of the list rather
            // than stopping at the card they belong to.
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

/// What a card row sits on: the card's fill, a hover wash, and the divider
/// that separates this row from the next one inside the same card.
///
/// The divider lives here rather than in the row's content because it belongs
/// to the card, not to either row — it has to survive whichever of the two the
/// pointer is over.
private struct CardRowSurface: View {
    let position: CardRowPosition
    let isHovering: Bool

    var body: some View {
        shape
            .fill(.background.secondary)
            .overlay {
                if isHovering {
                    shape.fill(.fill.quaternary)
                }
            }
            .overlay(alignment: .bottom) { divider }
            .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    /// Only the card's outermost corners round. Rounding every row turns one
    /// card into a stack of pills with notches between them.
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: position.topRadius,
            bottomLeadingRadius: position.bottomRadius,
            bottomTrailingRadius: position.bottomRadius,
            topTrailingRadius: position.topRadius
        )
    }

    @ViewBuilder
    private var divider: some View {
        if position.hasRowBelow {
            Rectangle()
                .fill(.separator)
                .frame(height: 1)
                .padding(.horizontal, ScadeDesign.cardDividerInset)
        }
    }
}
