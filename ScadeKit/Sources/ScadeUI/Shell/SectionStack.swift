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

    var body: some View {
        NavigationStack {
            content
                .navigationDestination(for: Education.self, destination: EducationDetailScreen.init)
                .navigationDestination(for: Subject.self, destination: SubjectDetailScreen.init)
                .navigationDestination(for: Grade.self, destination: GradeDetailScreen.init)
        }
    }
}

#Preview {
    SectionStack {
        EducationListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
