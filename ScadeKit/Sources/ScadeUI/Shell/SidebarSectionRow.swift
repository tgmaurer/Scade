#if os(macOS)
import SwiftUI

/// One section in the macOS sidebar.
///
/// **Why the app draws the selection instead of `List(selection:)`.** A
/// `List`'s own selection is an `NSTableView` selection underneath, and that
/// greys out whenever the table stops being first responder — which here is
/// the moment anything in the detail column is clicked, so the highlight was
/// grey almost all the time. That behaviour is right for a selection you're
/// acting on and wrong for this: these five rows are a mode switch, and the
/// highlight is answering "which section am I in", a question the answer to
/// doesn't change just because focus moved.
///
/// SwiftUI exposes no hook for it — the emphasis is AppKit's, below the level
/// `List` surfaces — so the row carries its own background instead.
struct SidebarSectionRow: View {
    let section: AppSection
    let isSelected: Bool
    let select: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: select) {
            Label(section.title, systemImage: section.systemImage)
                // Filling the row is the point here: a sidebar row is a
                // full-width target, and nothing shares the line with it.
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        // No padding of its own, and the highlight goes in the row's
        // background rather than behind the label. Both for the same reason:
        // the sidebar already has metrics — row height, insets, where a
        // selection sits — and every number added here is one that disagrees
        // with them. Padding the label indented the text past where the
        // system puts it and made the rows taller, and a highlight drawn
        // inside those insets could never reach as wide as a real selection.
        .listRowBackground(
            RoundedRectangle(cornerRadius: ScadeDesign.sidebarSelectionRadius)
                .fill(fill)
                // A row's background is the full width of the sidebar; a
                // macOS selection is not. Held back from both edges so it
                // floats in the column instead of running into the window
                // border on one side and the split divider on the other.
                .padding(.horizontal, ScadeDesign.sidebarSelectionInset)
        )
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: ScadeDesign.hoverDuration), value: isHovering)
        .accessibilityIdentifier(AccessibilityID.section(section))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var fill: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(ScadeDesign.accent)
        } else if isHovering {
            ScadeDesign.rowHoverFill
        } else {
            AnyShapeStyle(.clear)
        }
    }
}

#Preview {
    List {
        SidebarSectionRow(section: .home, isSelected: true) {}
        SidebarSectionRow(section: .educations, isSelected: false) {}
    }
    .listStyle(.sidebar)
}
#endif
