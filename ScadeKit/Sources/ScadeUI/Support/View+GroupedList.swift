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

    /// The card a row sits on, shaped for where in the card it sits, and lit
    /// when the pointer is over it. See `CardRow`.
    func cardRow(_ position: CardRowPosition, highlightsOnHover: Bool = true) -> some View {
        modifier(CardRow(position: position, highlightsOnHover: highlightsOnHover))
    }

    /// A section of a card list.
    ///
    /// Stops the list ruling its own line above the section's first row.
    /// `listSectionSeparator` only reaches that line from the section itself,
    /// never from the rows inside it — which is why hiding it per-row left the
    /// line above a card's first row still drawn.
    func cardSection() -> some View {
        listSectionSeparator(.hidden)
    }
}
