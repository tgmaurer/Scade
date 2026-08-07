import ScadeKit
import SwiftUI

/// One grade, compact enough to sit in a row of them.
///
/// The dashboard's job is "how am I doing", so a grade there needs its value
/// and how much it counts — nothing else. Date and description belong to the
/// grade's own screens.
///
/// The weight is dropped when it's the default 100%: printing it on every
/// chip makes the exceptions harder to spot, which is the opposite of what
/// showing it is for.
struct GradeChip: View {
    let grade: Grade
    /// Lit because the pointer is over it. Drawn here rather than layered on
    /// from outside so the chip has one fill, at one of two strengths, instead
    /// of two stacked fills that read as a third colour.
    var isHighlighted: Bool = false

    private var showsWeight: Bool {
        grade.weight != 1.0
    }

    private var fill: AnyShapeStyle {
        isHighlighted ? AnyShapeStyle(.fill.tertiary) : AnyShapeStyle(.fill.quaternary)
    }

    var body: some View {
        HStack(spacing: ScadeDesign.iconTextSpacing) {
            GradeValueLabel(grade.value)

            if showsWeight {
                WeightLabel(grade.weight)
                    .font(ScadeDesign.rowMeta)
                    .foregroundStyle(.secondary)
            }
        }
        .font(ScadeDesign.value)
        .padding(.horizontal, ScadeDesign.chipPadding)
        // A stated height, not padding: a subject row is sized to hold a chip,
        // so the chip has to be a known height for that to mean anything. A
        // floor rather than a fixed height so larger text still fits.
        .frame(minHeight: ScadeDesign.chipHeight)
        .background(
            RoundedRectangle(cornerRadius: ScadeDesign.badgeCornerRadius)
                .fill(fill)
        )
        .animation(.easeOut(duration: 0.12), value: isHighlighted)
    }
}

#Preview {
    FlowLayout {
        GradeChip(grade: Grade(subjectId: 1, value: 5.5, date: .today()))
        GradeChip(grade: Grade(subjectId: 1, value: 3.5, weight: 0.667, date: .today()))
        GradeChip(grade: Grade(subjectId: 1, value: 6.0, weight: 0.5, date: .today()))
    }
    .padding()
}
