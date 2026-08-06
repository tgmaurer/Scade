#if !os(macOS)
import SwiftUI

/// The iOS shell: a bottom tab bar, one navigation stack per tab.
///
/// This is what replaced the `NavigationSplitView` the whole app used to
/// share. On iPhone that collapsed into a stack whose root *was* the sidebar,
/// so changing section meant navigating back to a menu — which no iOS app
/// does (SPEC-POLISH §2.2).
///
/// Settings has no tab here; Home's toolbar carries it. See
/// `AppSection.showsSettingsSection`.
struct TabShell: View {
    @Binding var section: AppSection

    var body: some View {
        TabView(selection: $section) {
            Tab(
                AppSection.home.title,
                systemImage: AppSection.home.systemImage,
                value: .home
            ) {
                SectionStack {
                    HomeScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.home))

            Tab(
                AppSection.educations.title,
                systemImage: AppSection.educations.systemImage,
                value: .educations
            ) {
                SectionStack {
                    EducationListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.educations))

            Tab(
                AppSection.subjects.title,
                systemImage: AppSection.subjects.systemImage,
                value: .subjects
            ) {
                SectionStack {
                    SubjectListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.subjects))

            Tab(
                AppSection.grades.title,
                systemImage: AppSection.grades.systemImage,
                value: .grades
            ) {
                SectionStack {
                    GradeListScreen()
                }
            }
            .accessibilityIdentifier(AccessibilityID.section(.grades))
        }
    }
}

#Preview {
    @Previewable @State var section: AppSection = .home

    TabShell(section: $section)
        .environment(\.repositories, PreviewData.seededRepositories)
}
#endif
