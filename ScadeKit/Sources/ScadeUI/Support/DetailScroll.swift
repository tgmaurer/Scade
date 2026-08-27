import SwiftUI

/// The scrolling column a detail screen — and the macOS dashboard — is made
/// of: `DetailSection`s, one under the next.
///
/// Nothing pads the stack. Each card pads itself, which keeps the margin in
/// one place whether a card is first, last or alone.
struct DetailScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            // Holds the column open when there is nothing in it. A `VStack`
            // with no content is 0pt wide, and a `ScrollView` reports its
            // content's width — so an `.overlay` on this collapsed to a
            // couple of characters, which is what the dashboard's empty
            // state looked like with no educations: "Nothing to Track Yet"
            // set one letter per line. Populated it changes nothing; every
            // card already fills the width.
            .frame(maxWidth: .infinity, alignment: .leading)
            // Top only: every card carries its own bottom margin, so the last
            // one already ends clear of the window edge. On the content rather
            // than the scroll view — padding the scroll view shrinks its frame
            // and takes the scroller with it, leaving the scrollbar short of
            // the window edge (`CardGrid` has the same note).
            .padding(.top, ScadeDesign.contentMargin)
        }
    }
}
