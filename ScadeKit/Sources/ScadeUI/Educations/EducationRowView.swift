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
///
/// The two blocks are pushed apart rather than stacked, so that in a grid —
/// where every tile is as tall as the tallest in its row — the counts and
/// status sit on one line across the whole row instead of each floating
/// wherever its own content happened to end. Where there's no spare height,
/// as in the iOS list, the gap collapses to ordinary row spacing and the
/// layout is the stack it always was.
struct EducationRowView: View {
    let row: EducationRow

    /// The institution, when there is one — an empty string counts as none,
    /// so a blank field doesn't leave a stray separator behind.
    private var institution: String? {
        guard let institution = row.education.institution, institution.isEmpty == false else {
            return nil
        }
        return institution
    }

    private var years: String {
        "\(yearText(row.education.startDate.year))–\(yearText(row.education.endDate.year))"
    }

    /// Years are identifiers, not quantities — no thousands separator.
    private func yearText(_ year: Int) -> String {
        year.formatted(.number.grouping(.never))
    }

    /// Institution and years, on one line whatever the institution's length.
    ///
    /// Two `Text`s rather than one interpolated string, because they truncate
    /// differently: an institution can run to "gibb, Gewerblich Industrielle
    /// Berufsfachschule Bern" and has to give way, while the years are four
    /// digits that must not. One string would have put the years at the end of
    /// the line, where the ellipsis eats them first.
    ///
    /// One line and not two: a tile that wraps is taller than its neighbours,
    /// and since a grid row is as tall as the tallest tile in it, one long
    /// institution used to leave dead space under every other education on
    /// that row.
    private var contextLine: some View {
        HStack(spacing: 0) {
            if let institution {
                Text(institution)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    // The name is worth reading in full even when it doesn't
                    // fit — nothing else on the tile carries it.
                    .help(institution)

                Text(" · ")
            }

            Text(years)
                // Never the thing that gives way. Without this the two Texts
                // share the squeeze and the years truncate alongside the
                // institution, which loses the shorter and more useful half.
                .fixedSize()

            Spacer(minLength: 0)
        }
    }

    var body: some View {
        // Zero spacing, because the `Spacer` below carries the gap itself —
        // stack spacing either side of it would apply twice.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                    Text(row.education.name)
                        .font(ScadeDesign.rowTitle)
                        // Two lines, not one: the name is what identifies the
                        // education, and nothing else on the tile repeats it —
                        // "Informatiker EFZ Applikationsentwicklung" one-lined
                        // is indistinguishable from "Informatiker EFZ". Bounded
                        // all the same, because names are capped at 255
                        // characters and that's some fifteen lines here, which
                        // would drag every tile in the row down with it.
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    // Baseline-aligned, not centred: §2.4 asks for centring
                    // where the two rungs differ enough in size that a shared
                    // baseline strands the smaller one. These two are the
                    // same size, so the baseline is the thing that lines up.
                    AverageLabel(row.average)
                        .font(ScadeDesign.value)
                        .bold()
                }

                contextLine
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
            }

            // Takes up whatever height the tallest tile in the row leaves
            // over, so this block lands at the bottom of every tile rather
            // than trailing off wherever its own text ran out. `minLength`
            // is the gap when there's nothing spare — the iOS list row, and
            // the tallest tile in any grid row.
            Spacer(minLength: ScadeDesign.rowSpacing)

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
