import ScadeKit
import SwiftUI

/// One subject on the dashboard: what it's called, and how it's going.
///
/// The semester isn't repeated here — the section it sits in already says it
/// (SPEC-POLISH §2.3).
struct HomeSubjectRow: View {
    let item: HomeSubject

    var body: some View {
        NavigationLink(value: item.subject) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.subject.name)
                    .font(ScadeDesign.rowTitle)

                Spacer(minLength: 0)

                AverageLabel(item.average)
                    .font(ScadeDesign.value)
            }
        }
    }
}

#Preview {
    List {
        HomeSubjectRow(item: PreviewData.homeSubject())
        HomeSubjectRow(item: PreviewData.homeSubject(failing: true))
    }
}
