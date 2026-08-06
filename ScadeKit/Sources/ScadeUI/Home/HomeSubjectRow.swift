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
        HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
            NavigationLink(value: item.subject) {
                Text(item.subject.name)
                    .font(ScadeDesign.rowTitle)
                    .lineLimit(1)
                    .frame(minWidth: ScadeDesign.subjectColumnWidth, alignment: .leading)
                    // Inside the link, so the whole column is clickable. With
                    // the frame outside it the target was the glyphs alone,
                    // which is why clicks so often did nothing.
                    .contentShape(.rect)
            }
            .layoutPriority(1)

            if showsGrades {
                grades
            }

            Spacer(minLength: 0)

            AverageLabel(item.average)
                .font(ScadeDesign.value)
                .bold()
        }
        .padding(.vertical, ScadeDesign.rowVerticalPadding)
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
                    GradeChip(grade: grade)
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
