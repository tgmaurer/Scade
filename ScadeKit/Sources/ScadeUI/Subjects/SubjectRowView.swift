import ScadeKit
import SwiftUI

/// One subject in the list (SPEC §4).
///
/// Two lines, per the §2.4 ladder: what the subject *is* — its name with the
/// semester it belongs to, and the average as the trailing anchor — over the
/// education it hangs off and what it currently amounts to.
///
/// It was four lines, and three of them were spent badly. The institution was
/// printed in full on every row — it belongs to the education, not to the
/// subject, and repeating "gibb, Gewerblich Industrielle Berufsfachschule
/// Bern" down the whole list said nothing about any subject in it. The
/// semester had a line to itself when it belongs beside the name. And the
/// weight read "100%" on every row, which is the absence of weighting
/// announcing itself.
///
/// Carries no padding of its own; the list row it sits in supplies that.
struct SubjectRowView: View {
    let row: SubjectRow

    /// "Semester 3", not "Semester 3 of 8". How many semesters the education
    /// runs to is a fact about the education, and it's on that education's own
    /// screens — here it's the same number repeated down every row.
    private var semester: String {
        row.subject.semester.formatted(.number.grouping(.never))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text(row.subject.name)
                    .font(ScadeDesign.rowTitle)
                    // The row is one line high whatever it holds, so a long
                    // name gives way rather than pushing its neighbours down.
                    .lineLimit(1)

                Text("Semester \(semester)")
                    .font(ScadeDesign.rowMeta)
                    .foregroundStyle(.secondary)
                    // Beside the name because §2.4 makes the two of them
                    // together what identifies a subject — "Module 404" means
                    // little on its own in an eight-semester education. Pinned,
                    // so the name is what truncates: it's the longer of the
                    // two and the one with room to spare.
                    .fixedSize()

                Spacer(minLength: 0)

                AverageLabel(row.average)
                    .font(ScadeDesign.value)
                    .bold()
            }

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text(row.education.name)
                    .font(ScadeDesign.rowSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: ScadeDesign.rowSpacing) {
                    Text("^[\(row.gradeCount) grade](inflect: true)")

                    // Only when it isn't the default — see
                    // `WeightLabel.isMeaningful`.
                    if WeightLabel.isMeaningful(row.subject.weight) {
                        WeightLabel(row.subject.weight)
                    }

                    CompletionBadge(isCompleted: row.subject.completed)
                }
                .font(ScadeDesign.rowMeta)
                .fixedSize()
            }
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        SubjectRowView(row: PreviewData.subjectRow(name: "Analysis"))
        SubjectRowView(row: PreviewData.subjectRow(name: "Lineare Algebra", weight: 1.5))
        SubjectRowView(row: PreviewData.subjectRow(name: "Datenbanken", completed: true))
        SubjectRowView(row: PreviewData.subjectRow(name: "Verteilte Systeme und Nebenläufigkeit"))
    }
}
