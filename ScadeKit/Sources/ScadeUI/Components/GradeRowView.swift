import ScadeKit
import SwiftUI

/// One grade, as listed under a subject or on the grades list.
///
/// Shared rather than written twice, so the subject detail and the grades
/// list can't drift apart. `showsContext` adds the parent names, which the
/// top-level list needs and the subject detail doesn't.
struct GradeRowView: View {
    let item: GradeListItem
    var showsContext = true

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline) {
                GradeValueLabel(item.grade.value)
                    .font(.headline)

                Text(verbatim: "·")
                    .foregroundStyle(.secondary)

                WeightLabel(item.grade.weight)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text(item.grade.date.startOfDay(), format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let details = item.grade.description, details.isEmpty == false {
                Text(details)
                    .font(.subheadline)
            }

            if showsContext {
                Text("\(item.subject.name) · \(item.education.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    List {
        GradeRowView(
            item: GradeListItem(
                grade: Grade(
                    subjectId: 1, value: 5.5, weight: 0.5,
                    description: "Schlussprüfung", date: .today()
                ),
                subject: Subject(educationId: 1, name: "Analysis", semester: 2),
                education: PreviewData.education()
            )
        )
        GradeRowView(
            item: GradeListItem(
                grade: Grade(subjectId: 1, value: 3.25, date: .today()),
                subject: Subject(educationId: 1, name: "Analysis", semester: 2),
                education: PreviewData.education()
            ),
            showsContext: false
        )
    }
}
