#if os(macOS)
import SwiftUI

/// The macOS shell: a fixed-width sidebar and one detail column.
///
/// `TabView(.sidebarAdaptable)` renders as a split view here anyway, so this
/// looks the same — but it's a split view the app owns, which buys three
/// things the adaptive one can't give:
///
/// 1. `navigationSplitViewColumnWidth(_:)` with a single value fixes the
///    sidebar's width and takes away the resize handle. A wider sidebar shows
///    nothing more than a narrow one, so dragging it is a gesture with no
///    outcome.
/// 2. One `NavigationStack` for the whole window instead of one per tab, so
///    the push destinations are registered once.
/// 3. Rows the app draws itself, which keeps their accessibility identifiers —
///    AppKit's own sidebar discards them, and `ScadeUITests` drives this.
struct SidebarShell: View {
    @Binding var section: AppSection

    var body: some View {
        NavigationSplitView {
            // Not `List(selection:)`. The rows carry their own highlight, so
            // the current section stays marked once focus moves into the
            // detail column — see `SidebarSectionRow`. It also means the
            // app's selection can stay non-optional: `List` selects into an
            // optional, and some section is always showing.
            List(AppSection.visibleCases) { item in
                SidebarSectionRow(section: item, isSelected: item == section) {
                    section = item
                }
                .listRowSeparator(.hidden)
            }
            .navigationSplitViewColumnWidth(ScadeDesign.sidebarWidth)
        } detail: {
            SectionStack {
                SectionScreen(section: section)
            }
        }
    }
}

#Preview {
    @Previewable @State var section: AppSection = .home

    SidebarShell(section: $section)
        .environment(\.repositories, PreviewData.seededRepositories)
}
#endif
