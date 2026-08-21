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
/// **The title sits above the card and stays there.** It doesn't pin, it
/// doesn't scroll with anything but the card it names, and it needs no
/// background of its own because nothing ever passes underneath it. Sticky
/// headers were built here once and taken back out.
struct DetailSection<Content: View>: View {
    /// The header above the card. Cards that need no title omit it — the
    /// identity card is the record itself, not a labelled part of it.
    var title: LocalizedStringKey?

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            if let title {
                Text(title)
                    .font(ScadeDesign.rowSecondary)
                    .bold()
                    .foregroundStyle(.secondary)
                    // Lined up with the content inside the card below, not
                    // with the card's edge.
                    .padding(.horizontal, ScadeDesign.contentMargin + ScadeDesign.cardContentPadding)
            }

            card
        }
        // The gap to whatever comes next, carried here rather than as the
        // enclosing stack's spacing so the last card ends clear of the window
        // edge without the stack needing to know how many there are.
        .padding(.bottom, ScadeDesign.contentMargin)
    }

    private var card: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
                .fill(.background.secondary)
        )
        .padding(.horizontal, ScadeDesign.contentMargin)
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
