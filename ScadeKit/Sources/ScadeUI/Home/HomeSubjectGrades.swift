import ScadeKit
import SwiftUI

/// A subject's grades, laid out along its dashboard row.
///
/// They run *across* rather than stacking beneath the subject (SPEC-POLISH
/// §0.1). Stacking spent height, which is the scarce dimension on a dashboard,
/// to show what the width had room for. The old app's home screen had this
/// part right; what it got wrong was making the whole thing a bare table.
struct HomeSubjectGrades: View {
    let grades: [Grade]

    var body: some View {
        if grades.isEmpty {
            Text("No grades yet")
                .font(ScadeDesign.rowMeta)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout {
                ForEach(grades) { grade in
                    GradeChipButton(grade: grade)
                }
            }
        }
    }
}

#Preview {
    HomeSubjectGrades(grades: PreviewData.homeSubject().grades)
        .padding()
}
