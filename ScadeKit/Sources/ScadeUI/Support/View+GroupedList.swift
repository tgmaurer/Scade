import SwiftUI

extension View {
    /// The grouped, inset card treatment (SPEC-POLISH §2.5).
    ///
    /// iOS has this as a built-in style; macOS doesn't, and its default `List`
    /// draws a separator between every row, which is the "too many horizontal
    /// lines" problem. There, the same look is assembled: each row on a filled
    /// rounded rectangle that contrasts with the window background, and the
    /// separators that a card makes redundant taken away.
    ///
    /// A *filled* background rather than a stroked outline, deliberately — an
    /// outline is the Windows idiom the old app used, and it adds back the
    /// lines this exists to remove.
    func groupedListStyle() -> some View {
        #if os(macOS)
        listStyle(.inset)
            .scrollContentBackground(.hidden)
            // Padding rather than `contentMargins`, which the inset list style
            // ignores — without it the cards run into the window edge.
            .padding(.horizontal, ScadeDesign.contentMargin)
        #else
        listStyle(.insetGrouped)
        #endif
    }

    /// The card a row sits on, shaped for where in the card it sits.
    ///
    /// Separators follow the same rule: one *between* two rows of a card is
    /// doing real work, one under the last row separates it from nothing. The
    /// section separator goes either way — `listRowSeparator` doesn't reach
    /// the line a header draws under itself.
    func cardRow(_ position: CardRowPosition) -> some View {
        listRowSeparator(position.hasRowBelow ? .visible : .hidden)
            .listSectionSeparator(.hidden)
            .cardRowFill(position)
    }

    /// macOS only — iOS's grouped style draws its own card.
    @ViewBuilder
    private func cardRowFill(_ position: CardRowPosition) -> some View {
        #if os(macOS)
        listRowBackground(
            UnevenRoundedRectangle(
                topLeadingRadius: position.topRadius,
                bottomLeadingRadius: position.bottomRadius,
                bottomTrailingRadius: position.bottomRadius,
                topTrailingRadius: position.topRadius
            )
            .fill(.background.secondary)
        )
        #else
        self
        #endif
    }
}
