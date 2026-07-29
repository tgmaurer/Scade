import ScadeKit
import SwiftUI

/// One education in the list (SPEC §4).
struct EducationRowView: View {
    let row: EducationRow

    /// Institution and year span, skipping the institution when there isn't
    /// one rather than leaving a stray separator behind.
    private var contextLine: String {
        let years = "\(yearText(row.education.startDate.year))–\(yearText(row.education.endDate.year))"

        guard let institution = row.education.institution, institution.isEmpty == false else {
            return years
        }
        return "\(institution) · \(years)"
    }

    /// Years are identifiers, not quantities — no thousands separator.
    private func yearText(_ year: Int) -> String {
        year.formatted(.number.grouping(.never))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.education.name)
                    .font(.headline)

                Spacer(minLength: 0)

                AverageLabel(row.average)
                    .font(.headline)
            }

            Text(contextLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("^[\(row.subjectCount) subject](inflect: true) · ^[\(row.education.semesters) semester](inflect: true)")

                Spacer(minLength: 0)

                CompletionBadge(isCompleted: row.education.completed)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    List {
        EducationRowView(row: PreviewData.educationRow(average: 5.25))
        EducationRowView(row: PreviewData.educationRow(average: 3.5, completed: true))
        EducationRowView(row: PreviewData.educationRow(average: nil, subjectCount: 0))
    }
}
