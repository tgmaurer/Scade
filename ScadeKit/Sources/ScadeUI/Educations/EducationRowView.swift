import ScadeKit
import SwiftUI

/// One education in the list (SPEC §4).
///
/// Two blocks, per the §2.4 ladder: what the education *is* — its name, with
/// the average as the trailing anchor, over the institution and years that
/// qualify it — and then, set apart and a rung further down, what it
/// currently amounts to.
///
/// Carries no padding of its own. It's a card tile's content on macOS and a
/// list row's on iOS, and those two want different room around it.
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
        VStack(alignment: .leading, spacing: ScadeDesign.rowSpacing) {
            VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                    Text(row.education.name)
                        .font(ScadeDesign.rowTitle)

                    Spacer(minLength: 0)

                    // Baseline-aligned, not centred: §2.4 asks for centring
                    // where the two rungs differ enough in size that a shared
                    // baseline strands the smaller one. These two are the
                    // same size, so the baseline is the thing that lines up.
                    AverageLabel(row.average)
                        .font(ScadeDesign.value)
                        .bold()
                }

                Text(contextLine)
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
                    // A long institution name wraps rather than truncating,
                    // since the years at the end of the line are the half
                    // worth keeping — but not past two lines, which would
                    // make one tile drive the height of a whole grid row.
                    .lineLimit(2)
            }

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text("^[\(row.subjectCount) subject](inflect: true) · ^[\(row.education.semesters) semester](inflect: true)")

                Spacer(minLength: 0)

                CompletionBadge(isCompleted: row.education.completed)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Tiles") {
    CardGrid(items: [
        PreviewData.educationRow(id: 1, average: 5.25),
        PreviewData.educationRow(id: 2, average: 3.5, completed: true),
        PreviewData.educationRow(id: 3, average: nil, subjectCount: 0),
    ]) { row in
        EducationRowView(row: row).cardTile()
    }
}

#Preview("List row") {
    List {
        EducationRowView(row: PreviewData.educationRow(average: 5.25))
        EducationRowView(row: PreviewData.educationRow(average: 3.5, completed: true))
        EducationRowView(row: PreviewData.educationRow(average: nil, subjectCount: 0))
    }
}
