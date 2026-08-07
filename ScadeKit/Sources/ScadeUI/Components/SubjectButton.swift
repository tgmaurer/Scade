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
/// **It is exactly as wide as the name it draws.** Callers give the name
/// column its width with a `.frame` around this, which reserves the space
/// without handing it over: a `.frame` outside a `Button` positions the button
/// but doesn't extend what's clickable — that takes a `contentShape`, and the
/// one here is on the text. Reserving the column any other way is what broke
/// this screen twice, most recently with a `Spacer` alongside the button,
/// which gave the enclosing stack an infinite ideal width and left the rest of
/// the row nothing to lay out in.
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
                // Height only. Anything that grows the *width* here is
                // greedy, and this sits next to content that needs the room.
                .frame(minHeight: minimumHitHeight, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
    }

    /// A pointer can hit a word; a finger can't, so on a phone the target is
    /// grown to the HIG's floor. The width is left alone on both — a name is
    /// wide enough to hit, and widening it costs the average its place.
    private var minimumHitHeight: CGFloat? {
        #if os(macOS)
        nil
        #else
        ScadeDesign.touchTargetHeight
        #endif
    }

    private func open() {
        navigate(subject)
    }
}

#Preview {
    SubjectButton(subject: PreviewData.homeSubject().subject)
        .padding()
}
