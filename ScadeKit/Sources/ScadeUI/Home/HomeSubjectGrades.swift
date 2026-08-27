import ScadeKit
import SwiftUI

/// A subject's grades, laid out along its dashboard row, and the way to add
/// another.
///
/// They run *across* rather than stacking beneath the subject (SPEC-POLISH
/// §0.1). Stacking spent height, which is the scarce dimension on a dashboard,
/// to show what the width had room for. The old app's home screen had this
/// part right; what it got wrong was making the whole thing a bare table.
///
/// The add button is the last thing in the flow, so it wraps with the chips
/// instead of being pinned somewhere they can run into.
struct HomeSubjectGrades: View {
    let grades: [Grade]
    let canAddGrade: Bool
    let onAddGrade: () -> Void

    var body: some View {
        FlowLayout {
            if grades.isEmpty {
                // Kept even when the button is there: it says why the average
                // reads N/A, which a bare `+` doesn't.
                //
                // "No grades", not "no grades *yet*". The button beside it
                // already says more can be added, so "yet" only repeated it —
                // and on a completed subject, which has no button and can take
                // no more grades, it promised something untrue.
                Text("No grades")
                    .font(ScadeDesign.rowMeta)
                    .foregroundStyle(.secondary)
            }

            ForEach(grades) { grade in
                GradeChipButton(grade: grade)
            }

            if canAddGrade {
                AddGradeButton(action: onAddGrade)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        HomeSubjectGrades(grades: PreviewData.homeSubject().grades, canAddGrade: true) {}
        HomeSubjectGrades(grades: [], canAddGrade: true) {}
        HomeSubjectGrades(grades: [], canAddGrade: false) {}
    }
    .padding()
}
