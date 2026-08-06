import SwiftUI

/// Chooses the screen for a shell section.
///
/// The macOS shell has one detail column serving every section, so it needs
/// this; the iOS shell names its screens directly inside each `Tab`.
struct SectionScreen: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .home:
            HomeScreen()
        case .educations:
            EducationListScreen()
        case .subjects:
            SubjectListScreen()
        case .grades:
            GradeListScreen()
        case .settings:
            SettingsScreen()
        }
    }
}

#Preview {
    SectionStack {
        SectionScreen(section: .educations)
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
