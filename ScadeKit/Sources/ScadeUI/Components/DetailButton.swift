import SwiftUI

/// A record's title, as the way into its detail screen.
///
/// A button, not a link — in both senses. It navigates through `Navigator`
/// rather than `NavigationLink`, because several links in one `List` row
/// destroy the row's layout, and it *reads* as a button: the title keeps its
/// ordinary colour and the background lights under the pointer. Accent text
/// and underlining are the web's idea of a link, and on macOS they'd promise
/// something this doesn't do.
///
/// **It is exactly as wide as the title it draws.** Callers reserve whatever
/// column they want with a `.frame` around this, which reserves the space
/// without handing it over: a `.frame` outside a `Button` positions the button
/// but doesn't extend what's clickable — that takes a `contentShape`, and the
/// one here is on the text. Reserving space any other way is what broke the
/// dashboard twice, most recently with a `Spacer` alongside the button, which
/// gave the enclosing stack an infinite ideal width and left the rest of the
/// row nothing to lay out in.
///
/// Generic over what it opens so subjects, educations and anything else
/// reached this way share one treatment — the hover cue is a promise about
/// what a click does, and it should not vary by record type.
struct DetailButton<Destination: Hashable>: View {
    let title: String
    let destination: Destination
    var font: Font = ScadeDesign.rowTitle

    @Environment(\.navigate) private var navigate
    @State private var isHovering = false

    var body: some View {
        Button(action: open) {
            Text(title)
                .font(font)
                .lineLimit(1)
                .background {
                    RoundedRectangle(cornerRadius: ScadeDesign.badgeCornerRadius)
                        .fill(isHovering ? ScadeDesign.controlHoverFill : AnyShapeStyle(.clear))
                        // Outwards, so the title stays where it is and keeps
                        // its column alignment. Padding the text instead
                        // would indent every row on the screen to make room
                        // for a highlight that is usually invisible.
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
    /// grown to the HIG's floor. The width is left alone on both — a title is
    /// wide enough to hit, and widening it costs its neighbours their place.
    private var minimumHitHeight: CGFloat? {
        #if os(macOS)
        nil
        #else
        ScadeDesign.touchTargetHeight
        #endif
    }

    private func open() {
        navigate(destination)
    }
}

#Preview {
    let subject = PreviewData.homeSubject().subject

    DetailButton(title: subject.name, destination: subject)
        .padding()
}
