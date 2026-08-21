import SwiftUI

/// One titled card on a detail screen (SPEC-POLISH §2.5).
///
/// **A detail screen is a document, not a list**, and this is what it's built
/// from instead of `List` rows. Three things follow from the distinction, and
/// the third is what forced it:
///
/// - There is nothing to swipe. `.swipeActions` is the reason Home is a
///   `List` at all (§2.5); a detail screen's rows carry no actions, and its
///   Delete is in the toolbar.
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
struct DetailSection<Content: View>: View {
    /// The header above the card. Cards that need no title omit it — the
    /// identity card is the record itself, not a labelled part of it.
    var title: String?

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
                    .padding(.horizontal, ScadeDesign.cardTilePadding)
            }

            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ScadeDesign.cardCornerRadius)
                    .fill(.background.secondary)
            )
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
            .padding(ScadeDesign.cardTilePadding)
    }
}
