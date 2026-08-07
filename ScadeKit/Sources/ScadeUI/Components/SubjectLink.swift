import ScadeKit
import SwiftUI

/// A subject's name, as the way into its detail screen.
///
/// The link is the name and nothing else. A `NavigationLink` in a list row
/// otherwise claims the entire row, which turns the dashboard into a
/// navigation trap: it exists to be *read*, and every stray click would leave
/// it. Sizing this view to the name's own width — and letting the caller pad
/// around it — is what keeps that true.
///
/// Nothing about a name in a table says it can be clicked, so hover has to.
/// Colour *and* underline rather than colour alone: hover is the only cue
/// there is, so it shouldn't rest on seeing one particular hue.
struct SubjectLink: View {
    let subject: Subject

    @State private var isHovering = false

    var body: some View {
        NavigationLink(value: subject) {
            Text(subject.name)
                .font(ScadeDesign.rowTitle)
                .lineLimit(1)
                .foregroundStyle(isHovering ? ScadeDesign.accent : .primary)
                .underline(isHovering)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}

#Preview {
    NavigationStack {
        SubjectLink(subject: PreviewData.homeSubject().subject)
            .padding()
    }
}
