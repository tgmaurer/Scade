import SwiftUI

/// A whole card row as the way into a detail screen.
///
/// **Why not a plain `NavigationLink`.** macOS gives a `List` row that *is* a
/// link a presentation of its own, and part of that presentation is an accent
/// fill drawn across the full width of the row while it's pressed. A card row
/// is inset from the list by the window margin (`CardRow`), so the fill spans
/// the card *and* the margins either side of it — and since the card is drawn
/// over the middle, what's left showing is two indigo strips floating outside
/// the card with nothing under it.
///
/// `.buttonStyle(.plain)` does not take it away; the fill belongs to the row,
/// not to the label inside it. Insetting the list instead of the card would,
/// but that takes the scroller with it and leaves the scrollbar floating short
/// of the window edge — see `groupedListStyle`.
///
/// So on macOS the row is a `Button` that pushes through `Navigator`, which is
/// the escape that file already documents: a `List` leaves a button alone.
/// The three list screens escaped this by becoming grids of tiles, where a
/// plain button in a `LazyVGrid` has no such presentation to give up; a
/// detail screen's sub-list is a `List` and needs the fix stated.
///
/// **A button on iOS too**, since the screen it sits on is no longer a `List`
/// there either — so the disclosure chevron a link row would have carried is
/// drawn here instead. `.buttonStyle(.plain)` keeps the row's own colours; a
/// link outside a `List` tints its whole label with the accent.
struct CardRowLink<Destination: Hashable, Content: View>: View {
    let destination: Destination
    @ViewBuilder let content: Content

    @Environment(\.navigate) private var navigate

    var body: some View {
        Button {
            navigate(destination)
        } label: {
            label
                // Without this only the text is the target, so the gaps
                // between the name, the average and the line beneath them
                // aren't clicks.
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        #if os(macOS)
        content
        #else
        HStack(spacing: ScadeDesign.rowSpacing) {
            content

            Image(systemName: "chevron.forward")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        #endif
    }
}
