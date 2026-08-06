import SwiftUI

extension View {
    /// The grouped, inset card treatment (SPEC-POLISH §2.5).
    ///
    /// iOS has this as a built-in style; macOS doesn't, and its default `List`
    /// draws a separator between every row, which is the "too many horizontal
    /// lines" problem. There, the same look is assembled: separators hidden,
    /// and each row on a filled rounded rectangle that contrasts with the
    /// window background.
    ///
    /// A *filled* background rather than a stroked outline, deliberately — an
    /// outline is the Windows idiom the old app used, and it adds back the
    /// lines this exists to remove.
    func groupedListStyle() -> some View {
        #if os(macOS)
        listStyle(.inset)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, ScadeDesign.contentMargin, for: .scrollContent)
        #else
        listStyle(.insetGrouped)
        #endif
    }

    /// The card a row sits on, and the separators it makes redundant.
    ///
    /// A card already groups what's inside it, so a rule between every row is
    /// saying the same thing twice — and a rule under the *last* row of a
    /// card, with nothing beneath it to separate, says nothing at all.
    /// Section separators go too: `listRowSeparator` alone doesn't reach the
    /// line a header draws under itself.
    func cardRowBackground() -> some View {
        #if os(macOS)
        listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
                    .fill(.background.secondary)
            )
        #else
        listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
        #endif
    }
}
