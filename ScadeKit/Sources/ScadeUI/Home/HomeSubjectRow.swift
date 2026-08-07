import ScadeKit
import SwiftUI

/// One subject on the dashboard: what it's called, how it's going, and — where
/// there's width for it — the grades behind the average.
///
/// The grades run *along* the row rather than stacking beneath it
/// (SPEC-POLISH §0.1). Stacking spent height, which is the scarce dimension on
/// a dashboard, to show something the width had room for. The old app's home
/// screen had this part right; what it got wrong was making the whole thing a
/// bare table.
///
/// The semester isn't repeated here — the section it sits in already says it.
struct HomeSubjectRow: View {
    let item: HomeSubject
    let showsGrades: Bool

    var body: some View {
        HStack(alignment: .center, spacing: ScadeDesign.rowSpacing) {
            name

            if showsGrades {
                grades
            }

            Spacer(minLength: 0)

            AverageLabel(item.average)
                .font(ScadeDesign.value)
                .bold()
        }
        .padding(.vertical, ScadeDesign.rowVerticalPadding)
        // A subject with no grades has no chips to give the row its height,
        // so it would sit shorter than its neighbours. The floor is derived
        // from the chip height for exactly that reason — see
        // `ScadeDesign.subjectRowHeight`.
        .frame(minHeight: ScadeDesign.subjectRowHeight)
    }

    /// The name column: the link, then whatever's left of the column.
    ///
    /// The width belongs to this stack rather than to the link, so the link
    /// stays as wide as the name it draws. Putting it on the link instead
    /// would make the empty remainder of the column navigate — a click well
    /// clear of any text would still leave the screen.
    private var name: some View {
        HStack(spacing: 0) {
            SubjectLink(subject: item.subject)
            Spacer(minLength: 0)
        }
        .frame(minWidth: ScadeDesign.subjectColumnWidth, alignment: .leading)
        .layoutPriority(1)
    }

    @ViewBuilder
    private var grades: some View {
        if item.grades.isEmpty {
            Text("No grades yet")
                .font(ScadeDesign.rowMeta)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout {
                ForEach(item.grades) { grade in
                    GradeChipLink(grade: grade)
                }
            }
        }
    }
}

#Preview {
    List {
        HomeSubjectRow(item: PreviewData.homeSubject(), showsGrades: true)
        HomeSubjectRow(item: PreviewData.homeSubject(failing: true), showsGrades: true)
        HomeSubjectRow(item: PreviewData.homeSubject(), showsGrades: false)
    }
}
