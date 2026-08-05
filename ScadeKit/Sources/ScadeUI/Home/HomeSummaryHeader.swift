import ScadeKit
import SwiftUI

/// The selected education's headline numbers (SPEC §4).
///
/// Reads as a header rather than as another list section (SPEC-POLISH §2.3):
/// the average is the number the screen exists for, so it gets the size, and
/// the counts drop to metadata underneath.
struct HomeSummaryHeader: View {
    let education: Education
    let average: Double?
    let subjectCount: Int
    let gradeCount: Int
    let semester: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text(education.name)
                        .font(.title2)
                        .bold()

                    if let institution = education.institution, institution.isEmpty == false {
                        Text(institution)
                            .font(ScadeDesign.rowSecondary)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(ScadeDesign.headlineNumber)
            }

            HStack(spacing: ScadeDesign.cardCornerRadius) {
                Text("^[\(subjectCount) subject](inflect: true)")
                Text("^[\(gradeCount) grade](inflect: true)")

                CompletionBadge(isCompleted: education.completed)

                Spacer(minLength: 0)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)

            if let semester {
                Text(
                    "Showing semester \(semester.formatted(.number.grouping(.never))) only — the average covers it alone."
                )
                .font(ScadeDesign.rowMeta)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    List {
        HomeSummaryHeader(
            education: PreviewData.education(),
            average: 5.11,
            subjectCount: 6,
            gradeCount: 24,
            semester: nil
        )
    }
}
