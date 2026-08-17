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
        // Nothing insets the list itself. Padding it — or `safeAreaPadding`,
        // which behaves the same — shrinks its whole frame and takes the
        // scroller with it, leaving the scrollbar floating short of the
        // window edge instead of sitting on it where macOS puts one.
        // `contentMargins` is the modifier for exactly this and `List`
        // ignores it, under `.inset` and `.plain` alike (measured, twice).
        //
        // So the margin lives on the things inside instead: `cardRow` insets
        // a row and the card behind it, `cardSectionHeader` insets a header.
        // Three places, one token, and the scroll view keeps its full width.
        listStyle(.inset)
            .scrollContentBackground(.hidden)
        #else
        listStyle(.insetGrouped)
        #endif
    }

    /// The card a row sits on, shaped for where in the card it sits, and lit
    /// when the pointer is over it. See `CardRow`.
    func cardRow(
        _ position: CardRowPosition,
        highlightsOnHover: Bool = true,
        maximumWidth: Double = .infinity
    ) -> some View {
        modifier(
            CardRow(
                position: position,
                highlightsOnHover: highlightsOnHover,
                maximumWidth: maximumWidth
            )
        )
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

    /// A section header, lined up with the cards below it.
    ///
    /// Headers aren't rows, so `cardRow` never reaches them and they'd sit at
    /// the list's own inset while the cards sat at ours. macOS only: iOS's
    /// grouped style already places its headers.
    @ViewBuilder
    func cardSectionHeader() -> some View {
        #if os(macOS)
        padding(.horizontal, ScadeDesign.contentMargin)
        #else
        self
        #endif
    }
}
