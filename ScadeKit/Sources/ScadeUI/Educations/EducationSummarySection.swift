import ScadeKit
import SwiftUI

/// The education's own details, above its subject list.
struct EducationSummarySection: View {
    let summary: EducationSummary
    let average: Double?

    private var education: Education { summary.education }

    var body: some View {
        Section {
            LabeledContent("Average") {
                AverageLabel(average)
            }

            if let institution = education.institution, institution.isEmpty == false {
                LabeledContent("Institution", value: institution)
            }

            LabeledContent("Starts") {
                Text(education.startDate.startOfDay(), format: .dateTime.day().month().year())
            }

            LabeledContent("Ends") {
                Text(education.endDate.startOfDay(), format: .dateTime.day().month().year())
            }

            LabeledContent("Semesters") {
                Text(education.semesters.formatted(.number.grouping(.never)))
            }

            LabeledContent("Subjects") {
                Text(summary.subjectCount.formatted(.number.grouping(.never)))
            }

            LabeledContent("Grades") {
                Text(summary.gradeCount.formatted(.number.grouping(.never)))
            }

            LabeledContent("Status") {
                CompletionBadge(isCompleted: education.completed)
            }
        }

        if let details = education.description, details.isEmpty == false {
            Section("Description") {
                Text(details)
            }
        }
    }
}

#Preview {
    List {
        EducationSummarySection(
            summary: EducationSummary(education: PreviewData.education(), subjects: []),
            average: 5.25
        )
    }
}
