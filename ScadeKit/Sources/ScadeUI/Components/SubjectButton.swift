import ScadeKit
import SwiftUI

/// A subject's name, as the way into its detail screen.
///
/// A button, not a link — in both senses. It navigates through `Navigator`
/// rather than `NavigationLink`, because several links in one `List` row
/// destroy the row's layout, and it *reads* as a button: the name keeps its
/// ordinary colour and the background lights under the pointer. Accent text
/// and underlining are the web's idea of a link, and on macOS they'd promise
/// something this doesn't do.
///
/// It is sized to the name it draws, so the caller can give the column its
/// width without making the empty remainder of that column clickable.
struct SubjectButton: View {
    let subject: Subject

    @Environment(\.navigate) private var navigate
    @State private var isHovering = false

    var body: some View {
        Button(action: open) {
            Text(subject.name)
                .font(ScadeDesign.rowTitle)
                .lineLimit(1)
                .background {
                    RoundedRectangle(cornerRadius: ScadeDesign.badgeCornerRadius)
                        .fill(isHovering ? AnyShapeStyle(.fill.quaternary) : AnyShapeStyle(.clear))
                        // Outwards, so the name stays where it is and keeps
                        // its column alignment. Padding the text instead
                        // would indent every subject on the screen to make
                        // room for a highlight that is usually invisible.
                        .padding(.horizontal, -ScadeDesign.chipPadding)
                        .padding(.vertical, -ScadeDesign.hoverInset)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
    }

    private func open() {
        navigate(subject)
    }
}

#Preview {
    SubjectButton(subject: PreviewData.homeSubject().subject)
        .padding()
}
