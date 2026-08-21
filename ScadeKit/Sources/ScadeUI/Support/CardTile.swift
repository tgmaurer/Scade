import SwiftUI

/// A card that stands on its own rather than sitting in a stack of them
/// (SPEC-POLISH §2.5).
///
/// The same surface as a `CardRow` — a filled, rounded secondary background
/// contrasting with the window, never a stroked outline — so the app has one
/// card and not two that nearly match. What differs is that a tile has no
/// neighbour above or below to be divided from: it rounds on all four corners
/// and draws no divider at all.
///
/// A `ViewModifier` rather than a `View` extension for the same reason
/// `CardRow` is one: hover is state, and an extension has nowhere to keep it.
struct CardTile: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, ScadeDesign.cardContentPadding)
            .padding(.vertical, ScadeDesign.cardTilePadding)
            // Fills its grid cell. A row of tiles is as tall as the tallest
            // one in it, and without this a shorter tile draws its card at
            // its own height and floats in the space left over.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(surface)
            // Without this only the text answers the pointer, so the
            // highlight flickers as it crosses the gaps between fields.
            .contentShape(.rect)
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
    }

    private var surface: some View {
        shape
            .fill(.background.secondary)
            .overlay {
                if isHovering {
                    shape.fill(ScadeDesign.rowHoverFill)
                }
            }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
    }
}

extension View {
    /// Puts this on a card of its own, lit when the pointer is over it.
    /// See `CardTile`.
    func cardTile() -> some View {
        modifier(CardTile())
    }
}
