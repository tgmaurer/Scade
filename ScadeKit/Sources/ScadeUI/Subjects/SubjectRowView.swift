import ScadeKit
import SwiftUI

/// One subject, as a card tile on macOS and a list row on iOS (SPEC §4).
///
/// Three blocks, per the §2.4 ladder: the name with the average as its
/// trailing anchor, the semester and education that place it, and — pushed to
/// the bottom so it lands on one line across a whole grid row — what it
/// currently amounts to.
///
/// It once spent four lines saying this. The institution was printed in full
/// on every row, which belongs to the education rather than the subject; the
/// semester had a line to itself; and the weight read "100%" throughout,
/// which is the absence of weighting announcing itself.
///
/// Carries no padding of its own — `cardTile` supplies it on macOS, the list
/// row on iOS, and those two want different room.
struct SubjectRowView: View {
    let row: SubjectRow

    /// "Semester 3", not "Semester 3 of 8". How many semesters the education
    /// runs to is a fact about the education, and it's on that education's own
    /// screens — here it would be the same number on every tile.
    private var semester: String {
        row.subject.semester.formatted(.number.grouping(.never))
    }

    /// Semester and parent education, on one line however long the education's
    /// name is.
    ///
    /// Two `Text`s rather than one string because they give way differently:
    /// the education is unbounded and truncates, the semester is a word and a
    /// digit and must not. Trailing position for the long one, so the ellipsis
    /// lands where there's least to lose.
    private var contextLine: some View {
        HStack(spacing: 0) {
            Text("Semester \(semester)")
                .fixedSize()

            Text(" · ")

            Text(row.education.name)
                .lineLimit(1)
                .truncationMode(.tail)
                // Worth reading in full when it doesn't fit: nothing else on
                // the tile carries it.
                .help(row.education.name)

            Spacer(minLength: 0)
        }
    }

    var body: some View {
        // Zero spacing; the `Spacer` below carries the gap itself, and stack
        // spacing either side of it would apply twice.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                    Text(row.subject.name)
                        .font(ScadeDesign.rowTitle)
                        // Two lines, like an education's name and for the same
                        // reason: it identifies the subject and nothing else on
                        // the tile repeats it, but names run to 255 characters
                        // and a tile that tall would drag its whole grid row.
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    AverageLabel(row.average)
                        .font(ScadeDesign.value)
                        .bold()
                }

                contextLine
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
            }

            // Takes whatever height the tallest tile in the row leaves over,
            // so this block lands at the bottom of every tile rather than
            // trailing off wherever its own text ran out. `minLength` is the
            // gap where there's nothing spare — the iOS list row, and the
            // tallest tile in any grid row.
            Spacer(minLength: ScadeDesign.rowSpacing)

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text("^[\(row.gradeCount) grade](inflect: true)")

                // Only when it isn't the default — see
                // `WeightLabel.isMeaningful`.
                if WeightLabel.isMeaningful(row.subject.weight) {
                    WeightLabel(row.subject.weight)
                }

                Spacer(minLength: 0)

                CompletionBadge(isCompleted: row.subject.completed)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Tiles") {
    CardGrid(items: [
        PreviewData.subjectRow(id: 1, name: "Analysis"),
        PreviewData.subjectRow(id: 2, name: "Lineare Algebra", weight: 1.5),
        PreviewData.subjectRow(id: 3, name: "Datenbanken", completed: true),
        PreviewData.subjectRow(id: 4, name: "Verteilte Systeme und Nebenläufigkeit"),
    ]) { row in
        SubjectRowView(row: row).cardTile()
    }
}

#Preview("List row") {
    List {
        SubjectRowView(row: PreviewData.subjectRow(name: "Analysis"))
        SubjectRowView(row: PreviewData.subjectRow(name: "Lineare Algebra", weight: 1.5))
        SubjectRowView(row: PreviewData.subjectRow(name: "Datenbanken", completed: true))
    }
}
