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

    private var showsWeight: Bool {
        grade.weight != 1.0
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
        .padding(.vertical, ScadeDesign.chipPadding / 2)
        .background(
            RoundedRectangle(cornerRadius: ScadeDesign.badgeCornerRadius)
                .fill(.fill.quaternary)
        )
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
