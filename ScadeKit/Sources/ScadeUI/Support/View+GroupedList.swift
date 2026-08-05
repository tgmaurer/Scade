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
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
        #else
        listStyle(.insetGrouped)
        #endif
    }

    /// The card a row sits on. macOS only — iOS's grouped style draws it.
    func cardRowBackground() -> some View {
        #if os(macOS)
        listRowBackground(
            RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
                .fill(.background.secondary)
        )
        #else
        self
        #endif
    }
}
