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

    /// `List` selects into an optional; the app's selection never is, since
    /// some section is always showing. This is the adapter between the two,
    /// and it refuses `nil` rather than inventing a "nothing selected" state
    /// the rest of the app would have to handle.
    private var selection: Binding<AppSection?> {
        Binding(get: { section }, set: { section = $0 ?? section })
    }

    var body: some View {
        NavigationSplitView {
            List(AppSection.visibleCases, selection: selection) { item in
                Label(item.title, systemImage: item.systemImage)
                    // Combined first: without it the identifier settles on the
                    // symbol rather than the row.
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AccessibilityID.section(item))
                    .tag(item)
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
