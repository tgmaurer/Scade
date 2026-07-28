import SwiftUI

/// Chooses the screen for the selected sidebar section.
///
/// Sits inside the one `NavigationStack` in `RootView`, so each
/// `navigationDestination(for:)` is registered exactly once for the whole app
/// rather than once per screen that happens to link somewhere.
struct SectionDetailView: View {
    let section: SidebarSection

    var body: some View {
        switch section {
        case .home:
            ComingSoonScreen(section: section)
        case .educations:
            ComingSoonScreen(section: section)
        case .subjects:
            ComingSoonScreen(section: section)
        case .grades:
            ComingSoonScreen(section: section)
        case .settings:
            ComingSoonScreen(section: section)
        }
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: .educations)
    }
}
