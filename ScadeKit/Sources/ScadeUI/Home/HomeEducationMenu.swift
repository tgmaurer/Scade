import ScadeKit
import SwiftUI

/// Picks which education the dashboard is showing.
struct HomeEducationMenu: View {
    let educations: [Education]
    @Binding var selection: Int64?

    var body: some View {
        Menu("Education", systemImage: "graduationcap") {
            // Inline, or macOS gives the picker a submenu of its own: the
            // menu drops down to a single "Education" item you then have to
            // hover into to reach any education. One extra level in front of
            // the only thing the menu is for.
            Picker("Education", selection: $selection) {
                ForEach(educations) { education in
                    Text(education.name).tag(education.id)
                }
            }
            .pickerStyle(.inline)
        }
        .disabled(educations.isEmpty)
        .help("Choose which education the dashboard shows")
        .accessibilityIdentifier(AccessibilityID.Home.educationMenu)
    }
}
