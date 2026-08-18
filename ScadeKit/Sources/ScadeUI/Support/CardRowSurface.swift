import SwiftUI

/// What a card row sits on: the card's fill, a hover wash, and the divider
/// that separates this row from the next one inside the same card.
///
/// The divider lives here rather than in the row's content because it belongs
/// to the card, not to either row — it has to survive whichever of the two the
/// pointer is over.
struct CardRowSurface: View {
    let position: CardRowPosition
    let isHovering: Bool

    var body: some View {
        shape
            .fill(.background.secondary)
            .overlay {
                if isHovering {
                    shape.fill(ScadeDesign.rowHoverFill)
                }
            }
            .overlay(alignment: .bottom) { divider }
            // A row background spans the full width of the list, and the list
            // is no longer inset — so the card would run into the window edge
            // without this. Matches the row content's own margin.
            .padding(.horizontal, ScadeDesign.contentMargin)
            .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
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
