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
            // Centred, not baseline-aligned. Sharing a baseline with a number
            // this much larger pins the name's *bottom* to the number's, so
            // all the slack lands above it and the name reads as having
            // slipped down. Centred, the space is split evenly and the name
            // sits in the middle of the figure it belongs to.
            //
            // The institution is a row of its own rather than stacked with
            // the name inside this one, which is what made the name the top
            // of a two-line block instead of a thing to centre. It lands in
            // the same place on screen either way.
            HStack(alignment: .center) {
                // The name is the way to the education; the rest of the card
                // is figures and stays inert (§2.8).
                DetailButton(
                    title: education.name,
                    destination: education,
                    font: .title2.bold()
                )

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(ScadeDesign.headlineNumber)
            }

            if let institution = education.institution, institution.isEmpty == false {
                Text(institution)
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
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
