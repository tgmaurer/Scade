import SwiftUI

/// Adds a grade to the subject whose row it sits in.
///
/// Chip-shaped and chip-sized, at the end of that subject's grades, because
/// that is where the thing it makes will appear. The row already reserves a
/// chip's height, so this costs no space at all.
///
/// **Its absence is the completion state.** A completed subject can't take
/// new grades (SPEC §4), so the button isn't drawn — which means the row says
/// whether a subject is finished without spending a badge, a colour or a word
/// on saying so. That only works if it's the *only* reason the button is
/// missing, so there's no disabled variant: it's here or the subject is done.
///
/// The glyph is secondary while a grade's value is not: same shape and weight
/// as its neighbours, but never mistakable for one of them at a glance.
struct AddGradeButton: View {
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(ScadeDesign.chipGlyph)
                .foregroundStyle(.secondary)
                .frame(width: ScadeDesign.chipHeight, height: ScadeDesign.chipHeight)
                .background(
                    RoundedRectangle(cornerRadius: ScadeDesign.badgeCornerRadius)
                        .fill(isHovering ? ScadeDesign.controlHoverFill : ScadeDesign.controlFill)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Above `accessibilityLabel`, and it has to stay there: applied
        // after it, no tooltip appears at all. Measured, not guessed — the
        // same modifier one line lower showed nothing however long the
        // pointer rested on the button.
        .help("Add a grade to this subject")
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
        // The glyph alone reads as "plus" to VoiceOver, which says what it
        // looks like rather than what it does.
        .accessibilityLabel("Add Grade")
    }
}

#Preview {
    AddGradeButton {}
        .padding()
}
