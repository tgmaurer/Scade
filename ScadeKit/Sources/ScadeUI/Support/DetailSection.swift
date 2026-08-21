import SwiftUI

/// One titled card on a detail screen (SPEC-POLISH §2.5).
///
/// **A detail screen is a document, not a list**, and this is what it's built
/// from instead of `List` rows. Three things follow from the distinction, and
/// the third is what forced it:
///
/// - There is nothing to swipe. `.swipeActions` is the reason iOS keeps a
///   `List` (§2.5); a detail screen's rows carry no actions, and its Delete
///   is in the toolbar.
/// - There is nothing to select or reorder, which is the rest of what a
///   `List` is for.
/// - **A macOS `List` swallows the drag that selects text.** Every `Text` in
///   one is inert however `.textSelection(.enabled)` is applied — on the
///   `Text`, on the row, or on the list itself; all three were tried and
///   measured. A detail screen is exactly where selecting text matters: an
///   institution's full name, a date, an average, a description worth pasting
///   somewhere else.
///
/// The card is drawn here rather than borrowed from `.insetGrouped`, so both
/// platforms get the same one instead of iOS getting the system's and macOS
/// assembling a lookalike.
///
/// **A function returning a `Section`, not a `View` of its own.** `DetailScroll`
/// pins section headers, and a `LazyVStack` pins only a `Section` it can *see*
/// — wrapped inside a custom `View`, the pinning silently does nothing at all
/// (built that way first, and the headers scrolled away as before). The same
/// constraint reaches one level up: whatever calls this has to be a
/// `@ViewBuilder` too, never a `View` struct holding sections.
///
/// It also carries its own margins, for the same reason: a pinned header has
/// to paint the full width of the scroll view, so the margin can't live on
/// the stack above or the content would scroll visibly through the gaps
/// either side of it.
func DetailSection<Content: View>(
    /// The header above the card. Cards that need no title omit it — the
    /// identity card is the record itself, not a labelled part of it.
    title: LocalizedStringKey? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    Section {
        DetailCard(content: content)
    } header: {
        DetailSectionHeader(title: title)
    }
}

/// The rounded surface a section's rows sit on.
struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
                .fill(.background.secondary)
        )
        .padding(.horizontal, ScadeDesign.contentMargin)
        // The gap to whatever comes next. Carried here rather than as the
        // stack's spacing, for the same reason as the margin.
        .padding(.bottom, ScadeDesign.contentMargin)
    }
}

/// A section's title, drawn above its card and pinned while the card scrolls
/// past underneath.
struct DetailSectionHeader: View {
    let title: LocalizedStringKey?

    var body: some View {
        if let title {
            Text(title)
                .font(ScadeDesign.rowSecondary)
                .bold()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Lined up with the content inside the card below, not with
                // the card's edge.
                .padding(.horizontal, ScadeDesign.contentMargin + ScadeDesign.cardContentPadding)
                .padding(.bottom, ScadeDesign.iconTextSpacing)
                // Opaque, and full width: while it's pinned, rows pass
                // underneath it.
                .background(.background)
        }
    }
}

/// A block of text as a card's whole content — a description, or a "nothing
/// here yet" line.
struct DetailSectionText<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ScadeDesign.cardContentPadding)
            .padding(.vertical, ScadeDesign.cardTilePadding)
    }
}
