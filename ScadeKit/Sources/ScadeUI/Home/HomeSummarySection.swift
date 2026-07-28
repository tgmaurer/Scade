import ScadeKit
import SwiftUI

/// The selected education's headline numbers (SPEC §4).
struct HomeSummarySection: View {
    let education: Education
    let average: Double?
    let subjectCount: Int
    let gradeCount: Int
    let semester: Int?

    var body: some View {
        Section {
            LabeledContent("Average") {
                AverageLabel(average)
                    .font(.headline)
            }

            LabeledContent("Subjects") {
                Text(subjectCount.formatted(.number.grouping(.never)))
            }

            LabeledContent("Grades") {
                Text(gradeCount.formatted(.number.grouping(.never)))
            }

            if let semester {
                LabeledContent("Showing") {
                    Text("Semester \(semester.formatted(.number.grouping(.never))) only")
                }
            }

            LabeledContent("Status") {
                CompletionBadge(isCompleted: education.completed)
            }
        } header: {
            Text(education.name)
        } footer: {
            if semester != nil {
                Text("The average covers the filtered semester only.")
            }
        }
    }
}
