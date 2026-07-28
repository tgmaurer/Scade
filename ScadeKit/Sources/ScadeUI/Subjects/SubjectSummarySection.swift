import ScadeKit
import SwiftUI

/// The subject's own details, above its grade list.
struct SubjectSummarySection: View {
    let summary: SubjectSummary
    let average: Double?

    private var subject: Subject { summary.subject }

    var body: some View {
        Section {
            LabeledContent("Average") {
                AverageLabel(average)
            }

            LabeledContent("Education", value: summary.education.name)

            if let institution = summary.education.institution, institution.isEmpty == false {
                LabeledContent("Institution", value: institution)
            }

            LabeledContent("Semester") {
                Text("\(subject.semester.formatted(.number.grouping(.never))) of \(summary.education.semesters.formatted(.number.grouping(.never)))")
            }

            LabeledContent("Weight") {
                WeightLabel(subject.weight)
            }

            LabeledContent("Grades") {
                Text(summary.gradeCount.formatted(.number.grouping(.never)))
            }

            LabeledContent("Status") {
                CompletionBadge(isCompleted: subject.completed)
            }
        }

        if let details = subject.description, details.isEmpty == false {
            Section("Description") {
                Text(details)
            }
        }
    }
}
