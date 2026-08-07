import ScadeKit
import SwiftUI

/// One subject on the dashboard: what it's called, how it's going, and — where
/// there's width for it — the grades behind the average.
///
/// Nothing in the row is a `NavigationLink`; the name and the chips are
/// buttons that push. See `Navigator` for why, and SPEC-POLISH §2.8.
///
/// The semester isn't repeated here — the section it sits in already says it.
struct HomeSubjectRow: View {
    let item: HomeSubject
    let showsGrades: Bool

    var body: some View {
        HStack(alignment: .center, spacing: ScadeDesign.rowSpacing) {
            HomeSubjectName(subject: item.subject)
                .layoutPriority(1)

            if showsGrades {
                HomeSubjectGrades(grades: item.grades)
            }

            Spacer(minLength: 0)

            AverageLabel(item.average)
                .font(ScadeDesign.value)
                .bold()
        }
        .padding(.vertical, ScadeDesign.rowVerticalPadding)
        // A subject with no grades has no chips to give the row its height, so
        // it would sit shorter than its neighbours. The floor is derived from
        // the chip height for that reason — see `ScadeDesign.subjectRowHeight`.
        .frame(minHeight: ScadeDesign.subjectRowHeight)
    }
}

#Preview {
    List {
        HomeSubjectRow(item: PreviewData.homeSubject(), showsGrades: true)
        HomeSubjectRow(item: PreviewData.homeSubject(failing: true), showsGrades: true)
        HomeSubjectRow(item: PreviewData.homeSubject(), showsGrades: false)
    }
}
