import ScadeKit
import SwiftUI

/// Picks which education the dashboard is showing.
struct HomeEducationMenu: View {
    let educations: [Education]
    @Binding var selection: Int64?

    var body: some View {
        Menu("Education", systemImage: "graduationcap") {
            Picker("Education", selection: $selection) {
                ForEach(educations) { education in
                    Text(education.name).tag(education.id)
                }
            }
        }
        .disabled(educations.isEmpty)
        .accessibilityIdentifier(AccessibilityID.Home.educationMenu)
    }
}
