import SwiftUI

/// Stands in for a screen that hasn't been built yet.
///
/// Temporary: each section replaces this as its screen lands. Delete the file
/// once nothing references it.
struct ComingSoonScreen: View {
    let section: SidebarSection

    var body: some View {
        ContentUnavailableView(
            section.title,
            systemImage: section.systemImage,
            description: Text("This screen hasn't been built yet.")
        )
        .navigationTitle(section.title)
    }
}

#Preview {
    NavigationStack {
        ComingSoonScreen(section: .grades)
    }
}
