import SwiftUI

/// The app's section list.
struct SidebarView: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            Label(section.title, systemImage: section.systemImage)
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
