import ScadeKit
import SwiftUI

/// A grade chip that opens the grade it shows.
///
/// Separate from `GradeChip` so the chip stays a way of *drawing* a grade —
/// it's the same shape in places that don't navigate — and so that the
/// hovered state has somewhere of its own to live.
struct GradeChipLink: View {
    let grade: Grade

    @State private var isHovering = false

    var body: some View {
        NavigationLink(value: grade) {
            GradeChip(grade: grade, isHighlighted: isHovering)
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    NavigationStack {
        FlowLayout {
            GradeChipLink(grade: Grade(subjectId: 1, value: 5.5, date: .today()))
            GradeChipLink(grade: Grade(subjectId: 1, value: 3.5, weight: 0.5, date: .today()))
        }
        .padding()
    }
}
