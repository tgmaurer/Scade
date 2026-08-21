import ScadeKit
import SwiftUI

/// One section's navigation stack, with every push destination registered.
///
/// Each `Tab` owns its own stack, so `navigationDestination(for:)` has to be
/// registered once *per tab* rather than once for the app — the registrations
/// only apply to the stack they're inside. Keeping them here means there is
/// still a single copy in the source: four hand-maintained copies is how one
/// tab quietly loses a detail screen while the others keep working.
struct SectionStack<Content: View>: View {
    @ViewBuilder let content: Content

    /// Held here so rows that can't be `NavigationLink`s can still push. See
    /// `Navigator` for which ones those are and why.
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Education.self) {
                    navigable(EducationDetailScreen(education: $0))
                }
                .navigationDestination(for: Subject.self) {
                    navigable(SubjectDetailScreen(subject: $0))
                }
                .navigationDestination(for: Grade.self) {
                    navigable(GradeDetailScreen(grade: $0))
                }
                .environment(\.navigate, navigator)
                // Only at the root, which is why it lives here rather than in
                // the shell: this is where the path is known. See
                // `windowTitlePrefix`.
                #if os(macOS)
                .windowTitlePrefix(path.isEmpty ? "Scade" : nil)
                #endif
        }
    }

    private var navigator: Navigator {
        Navigator { path.append($0) }
    }

    /// Hands a *pushed* screen the navigator as well.
    ///
    /// A pushed destination does not inherit it otherwise — measured, not
    /// assumed: with the environment applied to the stack, and again applied
    /// inside it beneath the registrations, a button on a detail screen ran
    /// its action and pushed nothing, because `navigate` was still the
    /// do-nothing default. Only the root content was ever reached.
    ///
    /// It went unnoticed because every earlier caller was on Home, which *is*
    /// root content. It stops being an edge case the moment a detail screen
    /// has a row or a parent link that navigates — see `CardRowLink` and
    /// §0.1's "detail screens should link to their parents".
    private func navigable(_ screen: some View) -> some View {
        screen.environment(\.navigate, navigator)
    }
}

#Preview {
    SectionStack {
        EducationListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
