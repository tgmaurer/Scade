import SwiftUI

/// The scrolling column a detail screen — and the macOS dashboard — is made
/// of: `DetailSection`s, one under the next, with their headers pinned.
///
/// Pinned because a `List` pins its section headers and this replaced one
/// (§0.1). "Semester 4" scrolling away as you read down a long education
/// leaves the rows it labels unlabelled, which is the whole job of the
/// header.
///
/// Lazy for the same reason: `pinnedViews` is a `LazyVStack` feature, and it
/// only sees a `Section` — which is why `DetailSection` is one.
///
/// Nothing pads the stack. Each section pads itself, so a pinned header can
/// paint the full width of the scroll view rather than leaving the content
/// visible in the margins either side of it.
struct DetailScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                content
            }
            // Top only: every section carries its own bottom margin, so the
            // last one already ends clear of the window edge. On the content
            // rather than the scroll view — padding the scroll view shrinks
            // its frame and takes the scroller with it, leaving the scrollbar
            // short of the window edge (`CardGrid` has the same note).
            .padding(.top, ScadeDesign.contentMargin)
        }
    }
}
