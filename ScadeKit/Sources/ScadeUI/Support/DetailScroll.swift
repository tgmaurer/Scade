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
            // Top only: every card carries its own bottom margin, so the last
            // one already ends clear of the window edge. On the content rather
            // than the scroll view — padding the scroll view shrinks its frame
            // and takes the scroller with it, leaving the scrollbar short of
            // the window edge (`CardGrid` has the same note).
            .padding(.top, ScadeDesign.contentMargin)
        }
    }
}
