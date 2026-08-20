import ScadeKit
import SwiftUI

/// One grade, as a card tile on the grades list and a list row under a
/// subject (SPEC §4).
///
/// Shared rather than written twice, so the subject detail and the grades
/// list can't drift apart. `showsContext` adds the parent names, which the
/// top-level list needs and the subject detail doesn't.
///
/// Three blocks, the same grammar the education and subject tiles use: what
/// the record *is*, with its number as the trailing anchor; the context that
/// places it; and — pushed to the bottom so it lands on one line across a
/// whole grid row — when it happened and what it counted for.
///
/// **What names a grade is not a field but a fallback.** An education and a
/// subject each have a name; a grade has an optional description, and a great
/// many are saved without one. So the heading is the most specific thing
/// available: the description, or failing that the subject it belongs to. The
/// context line drops whichever of the two the heading took, so neither is
/// ever printed twice.
///
/// Where nothing at all names the grade — no description, and the subject
/// already known from the screen around it — the value takes the lead instead
/// of anchoring the right of an otherwise empty line. That's §2.4's "value
/// dominant" in the one case where the value really is all there is.
///
/// Carries no padding of its own — `cardTile` supplies it on macOS, the list
/// row on iOS, and those two want different room.
struct GradeRowView: View {
    let item: GradeListItem
    var showsContext = true

    /// The description, when there is one — an empty string counts as none,
    /// the same rule an education's institution follows.
    private var details: String? {
        guard let details = item.grade.description, details.isEmpty == false else { return nil }
        return details
    }

    /// What heads the tile: what the grade was for, or the subject it's in.
    /// `nil` only under a subject, for a grade saved without a description.
    ///
    /// Internal rather than private so the fallback can be asserted directly.
    /// Which of two strings heads a tile is invisible to a height
    /// measurement — both are one line — so the rendering tests that cover
    /// the rest of this view are structurally unable to see it.
    var heading: String? {
        details ?? (showsContext ? item.subject.name : nil)
    }

    /// Whether the subject still needs printing, or the heading already took
    /// it. Internal for the same reason as `heading`.
    var showsSubject: Bool {
        showsContext && details != nil
    }

    /// The parents that place the grade, on one line however long their names.
    ///
    /// Both are unbounded here, which is what makes this line different from
    /// the education tile's — there, a four-digit year could be pinned with
    /// `.fixedSize()` and the institution left to give way. Two unbounded
    /// names have to *share* the squeeze, so neither is pinned and neither is
    /// given priority: an `HStack` hands each flexible child its ideal width
    /// when it fits and splits what's left when it doesn't, so a short subject
    /// stays whole and the long education absorbs the difference, while two
    /// long ones each truncate rather than one eating the other.
    ///
    /// `lineLimit` on the line and not on the `Text`s inside it, because the
    /// separator is a `Text` too: squeezed towards zero width it wrapped, and
    /// a 255-character subject name made the tile a line taller — with each
    /// name already correctly held to one line.
    @ViewBuilder
    private var contextLine: some View {
        if showsContext {
            HStack(spacing: 0) {
                if showsSubject {
                    Text(item.subject.name)
                        .help(item.subject.name)

                    Text(" · ")
                }

                Text(item.education.name)
                    // Worth reading in full when it doesn't fit: nothing else
                    // on the tile carries it.
                    .help(item.education.name)

                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .truncationMode(.tail)
        }
    }

    var body: some View {
        // Zero spacing; the `Spacer` below carries the gap itself, and stack
        // spacing either side of it would apply twice.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                    if let heading {
                        Text(heading)
                            .font(ScadeDesign.rowTitle)
                            // Two lines, like the names on the other two
                            // tiles — but a description is capped at 2500
                            // characters rather than 255, so the bound does
                            // far more work here. A grid row is as tall as
                            // its tallest tile, and one essay would drag
                            // every grade beside it down.
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }

                    GradeValueLabel(item.grade.value)
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
            // gap where there's nothing spare — the iOS list row, the rows
            // under a subject, and the tallest tile in any grid row.
            Spacer(minLength: ScadeDesign.rowSpacing)

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text(item.grade.date.startOfDay(), format: .dateTime.day().month().year())

                Spacer(minLength: 0)

                // Only when it isn't the default — see
                // `WeightLabel.isMeaningful`. A list where every row read
                // "100%" was the absence of weighting announcing itself.
                if WeightLabel.isMeaningful(item.grade.weight) {
                    WeightLabel(item.grade.weight)
                }
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Tiles") {
    CardGrid(items: [
        PreviewData.gradeItem(id: 1, value: 5.5, weight: 0.5, details: "Schlussprüfung"),
        PreviewData.gradeItem(id: 2, value: 3.25, details: nil),
        PreviewData.gradeItem(id: 3, value: 6.0, details: "Vortrag über verteilte Systeme"),
        PreviewData.gradeItem(id: 4, value: 4.75, weight: 1.5, details: "Zwischenprüfung"),
    ]) { item in
        GradeRowView(item: item).cardTile()
    }
}

#Preview("List rows under a subject") {
    List {
        GradeRowView(
            item: PreviewData.gradeItem(id: 1, value: 5.5, weight: 0.5, details: "Schlussprüfung"),
            showsContext: false
        )
        GradeRowView(
            item: PreviewData.gradeItem(id: 2, value: 3.25, details: nil),
            showsContext: false
        )
    }
}
