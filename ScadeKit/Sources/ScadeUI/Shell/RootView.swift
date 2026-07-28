import ScadeKit
import SwiftUI

/// The whole app, minus the `App` shell that hosts it.
///
/// Everything the views need arrives through `repositories`; the App target
/// only has to open the database and hand it over.
public struct RootView: View {
    @State private var selection: SidebarSection? = .home
    @AppStorage("appTheme") private var theme: AppTheme = .system

    private let repositories: Repositories

    public init(repositories: Repositories) {
        self.repositories = repositories
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            NavigationStack {
                SectionDetailView(section: selection ?? .home)
                    // Registered here, once each for the whole app, rather
                    // than on every screen that happens to link somewhere.
                    .navigationDestination(for: Education.self) { education in
                        EducationDetailScreen(education: education)
                    }
                    .navigationDestination(for: Subject.self) { subject in
                        SubjectDetailScreen(subject: subject)
                    }
                    .navigationDestination(for: Grade.self) { grade in
                        GradeDetailScreen(grade: grade)
                    }
            }
        }
        .environment(\.repositories, repositories)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView(repositories: .inMemory)
}
