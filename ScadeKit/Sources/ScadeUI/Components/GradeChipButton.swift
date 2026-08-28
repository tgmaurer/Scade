import ScadeKit
import SwiftUI

/// A grade chip that opens the grade it shows.
///
/// Separate from `GradeChip` so the chip stays a way of *drawing* a grade —
/// the same shape is wanted in places that don't navigate — and so the hovered
/// state has somewhere of its own to live.
///
/// A `Button` rather than a `NavigationLink` for the reason in `Navigator`: a
/// row full of links is a row `List` will not lay out.
struct GradeChipButton: View {
    let grade: Grade

    @Environment(\.navigate) private var navigate
    @State private var isHovering = false

    var body: some View {
        Button(action: open) {
            GradeChip(grade: grade, isHighlighted: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        // The chip has room for the value and the weight and nothing else
        // (see `GradeChip`), so a grade's date — the one field every grade
        // has — is otherwise only readable by opening it. A help tag hands
        // it back without spending any of the row's width on it.
        .help(Text(grade.date.startOfDay(), format: .dateTime.day().month().year()))
    }

    private func open() {
        navigate(grade)
    }
}

#Preview {
    FlowLayout {
        GradeChipButton(grade: Grade(subjectId: 1, value: 5.5, date: .today()))
        GradeChipButton(grade: Grade(subjectId: 1, value: 3.5, weight: 0.5, date: .today()))
    }
    .padding()
}
