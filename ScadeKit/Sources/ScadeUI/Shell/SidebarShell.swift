#if os(macOS)
import SwiftUI

/// The macOS shell: a fixed-width sidebar and one detail column.
///
/// The structure Apple documents for `NavigationSplitView` — a `List` with a
/// selection binding in the sidebar, a `NavigationStack` in the detail — and
/// deliberately nothing more. Everything that was hand-built here has been
/// taken back out; see the two notes below, both of which are scars.
///
/// `TabView(.sidebarAdaptable)` renders as a split view here anyway, so this
/// looks the same — but it's a split view the app owns, which buys the sidebar
/// width: `navigationSplitViewColumnWidth(_:)` with a single value fixes it
/// and takes away the resize handle. A wider sidebar shows nothing more than a
/// narrow one, so dragging it is a gesture with no outcome.
struct SidebarShell: View {
    /// Optional because that's what `List` selects into, and owned here rather
    /// than passed in so it can be. Some section is always showing, so `nil`
    /// is read as Home rather than given a state of its own.
    @State private var section: AppSection? = .home

    var body: some View {
        NavigationSplitView {
            // `List(selection:)` and a plain `Label`, which is the whole of
            // it.
            //
            // The selection binding is not decoration. It is how a
            // `NavigationSplitView` learns that the detail column should be
            // replaced, and it takes the detail's navigation stack back to
            // its root as part of that. Rows drawn by hand set the same
            // `section` state, but the split view never heard about it: the
            // stack kept whatever was pushed, so choosing a section from a
            // detail screen swapped the root *underneath* it and looked like
            // nothing had happened until you navigated back.
            //
            // Those rows cost the full-row click target too — a button fills
            // the row's content, not the insets around it, so the margins
            // were dead — and brought a hover state macOS doesn't put there.
            List(AppSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.systemImage)
                    .accessibilityIdentifier(AccessibilityID.section(item))
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(ScadeDesign.sidebarWidth)
        } detail: {
            SectionStack {
                SectionScreen(section: section ?? .home)
            }
        }
        // What `⌘1`–`⌘4` set. The menu can't reach this state, so the shell
        // hands the menu a way in.
        .focusedSceneValue(\.selectSection, SectionSelector { section = $0 })
    }
}

#Preview {
    SidebarShell()
        .environment(\.repositories, PreviewData.seededRepositories)
}
#endif
