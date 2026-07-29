import ScadeKit
import SwiftUI

/// One subject in the list (SPEC §4).
struct SubjectRowView: View {
    let row: SubjectRow

    private var contextLine: String {
        guard let institution = row.education.institution, institution.isEmpty == false else {
            return row.education.name
        }
        return "\(row.education.name) · \(institution)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.subject.name)
                    .font(.headline)

                Spacer(minLength: 0)

                AverageLabel(row.average)
                    .font(.headline)
            }

            Text(contextLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("Semester \(row.subject.semester.formatted(.number.grouping(.never))) of \(row.education.semesters.formatted(.number.grouping(.never)))")

                Spacer(minLength: 0)

                WeightLabel(row.subject.weight)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("^[\(row.gradeCount) grade](inflect: true)")

                Spacer(minLength: 0)

                CompletionBadge(isCompleted: row.subject.completed)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    List {
        SubjectRowView(
            row: SubjectRow(
                SubjectSummary(
                    subject: Subject(educationId: 1, name: "Analysis", semester: 2, weight: 1.5),
                    education: PreviewData.education(),
                    grades: [
                        Grade(subjectId: 1, value: 5.5, date: .today()),
                        Grade(subjectId: 1, value: 3.75, date: .today()),
                    ]
                )
            )
        )
    }
}
