import ScadeKit
import SwiftUI

/// A dashboard subject's name, semester and average badge.
struct HomeSubjectHeader: View {
    let item: HomeSubject

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            NavigationLink(value: item.subject) {
                Text(item.subject.name)
            }

            Text("· Semester \(item.subject.semester.formatted(.number.grouping(.never)))")
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            AverageLabel(item.average)
        }
        .font(.subheadline)
        .textCase(nil)
    }
}
