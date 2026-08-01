import SwiftUI

/// The app's section list.
struct SidebarView: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            // Combined first: without it the identifier settles on the
            // symbol rather than the row, and a bare symbol isn't tappable.
            Label(section.title, systemImage: section.systemImage)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(AccessibilityID.sidebarSection(section))
        }
        .navigationTitle("Scade")
    }
}

#Preview {
    @Previewable @State var selection: SidebarSection? = .home

    NavigationSplitView {
        SidebarView(selection: $selection)
    } detail: {
        Text("Detail")
    }
}
