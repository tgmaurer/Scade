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
/// `AppSection`.
struct TabShell: View {
    /// Owned here, not passed in: each shell selects in the type its own
    /// control uses — a `TabView` in a non-optional, a `List` in an optional —
    /// and nothing outside needs to know which section is showing.
    @State private var section: AppSection = .home

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
    TabShell()
        .environment(\.repositories, PreviewData.seededRepositories)
}
#endif
