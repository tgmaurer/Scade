import SwiftUI

/// One row inside a detail screen's card: its padding, its hover wash, and
/// the divider to the row below it.
///
/// The `List`-free counterpart to `CardRow`, drawing the same surface through
/// the same `CardRowSurface` so there is one card in the app and not two that
/// nearly match. What differs is only where the margin lives: a `List` row
/// background spans the full list, so `CardRow` insets the card itself; here
/// the enclosing stack is already padded, so the surface takes none.
struct DetailCardRow<Content: View>: View {
    let position: CardRowPosition
    @ViewBuilder let content: Content

    @State private var isHovering = false

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ScadeDesign.cardTilePadding)
            .background(
                CardRowSurface(position: position, isHovering: isHovering, margin: 0)
            )
            // Without this only the text answers the pointer, so the
            // highlight flickers as it crosses the gaps between columns.
            .contentShape(.rect)
            .onHover { isHovering = $0 }
    }
}
