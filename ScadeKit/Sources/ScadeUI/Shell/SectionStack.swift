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
                .navigationDestination(for: Education.self, destination: EducationDetailScreen.init)
                .navigationDestination(for: Subject.self, destination: SubjectDetailScreen.init)
                .navigationDestination(for: Grade.self, destination: GradeDetailScreen.init)
        }
        .environment(\.navigate, Navigator { path.append($0) })
    }
}

#Preview {
    SectionStack {
        EducationListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
