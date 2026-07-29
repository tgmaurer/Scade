import ScadeKit
import SwiftUI

/// One of an education's subjects, as listed on the education detail screen.
struct EducationSubjectRowView: View {
    let subjectGrades: SubjectGrades
    let totalSemesters: Int

    /// Passed in already computed — the detail screen works it out once per
    /// load rather than once per `body`.
    let average: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(subjectGrades.subject.name)
                    .font(.headline)

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(.headline)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Semester \(subjectGrades.subject.semester.formatted(.number.grouping(.never))) of \(totalSemesters.formatted(.number.grouping(.never)))")

                Spacer(minLength: 0)

                WeightLabel(subjectGrades.subject.weight)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("^[\(subjectGrades.grades.count) grade](inflect: true)")

                Spacer(minLength: 0)

                CompletionBadge(isCompleted: subjectGrades.subject.completed)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    List {
        EducationSubjectRowView(
            subjectGrades: SubjectGrades(
                subject: Subject(educationId: 1, name: "Analysis", semester: 2, weight: 1.5),
                grades: [
                    Grade(subjectId: 1, value: 5.5, date: .today()),
                    Grade(subjectId: 1, value: 3.75, date: .today()),
                ]
            ),
            totalSemesters: 6,
            average: 4.625
        )
    }
}
