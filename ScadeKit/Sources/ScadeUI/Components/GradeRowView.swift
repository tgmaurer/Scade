import ScadeKit
import SwiftUI

/// One grade, as a card tile on the grades list and a row under a subject
/// (SPEC §4).
///
/// Shared rather than written twice, so the subject detail and the grades
/// list can't drift apart. `showsContext` decides which of two shapes it
/// takes, and they differ because the two screens ask different questions.
///
/// **On the grades list — every grade there is** — the question is *which
/// grade is this*, so the heading is the most specific thing available: the
/// description, or failing that the subject it belongs to. A grade has no
/// name field and its description is optional (SPEC §3.4), so what names it
/// is a fallback rather than a field. The context line drops whichever of the
/// two the heading took, so neither parent is printed twice.
///
/// **Under one subject** the question is *which of these*, and the answer is
/// the date: it is the one field every grade has, and the subject is already
/// known from the screen around it. So the date leads, the value anchors the
/// trailing edge, and the description hangs beneath as a note when there is
/// one.
///
/// That difference is the fix for a real complaint. With the description
/// heading both shapes, a column of grades under one subject put the date on
/// the first line for some rows and the second for others, and the rows read
/// as two different kinds of thing. Making the description *required* was
/// tried as a fix and undone — it could not work, because the grades already
/// saved without one are not migrated, so the mix would have been permanent.
/// See [SPEC-BACKLOG](../../../../docs/SPEC-BACKLOG.md).
///
/// **A missing description is missing, not a dash.** Once the labels are gone
/// (§2.4) there is no cell that has to be filled, and a column of em-dashes
/// is louder than the nothing it reports. Rows are one line or two; the two
/// things the eye tracks — the date and the number — never move.
///
/// Carries no padding of its own — `cardTile` supplies it on macOS,
/// `DetailCardRow` under a subject, the list row on iOS, and those want
/// different room.
struct GradeRowView: View {
    let item: GradeListItem
    var showsContext = true

    /// The description, when there is one — an empty string counts as none,
    /// the same rule an education's institution follows.
    private var details: String? {
        guard let details = item.grade.description, details.isEmpty == false else { return nil }
        return details
    }

    /// What heads the tile on the grades list: what the grade was for, or the
    /// subject it's in.
    ///
    /// Internal rather than private so the fallback can be asserted directly.
    /// Which of two strings heads a tile is invisible to a height
    /// measurement — both are one line — so the rendering tests that cover
    /// the rest of this view are structurally unable to see it.
    var heading: String? {
        showsContext ? (details ?? item.subject.name) : nil
    }

    /// Whether the subject still needs printing, or the heading already took
    /// it.
    var showsSubject: Bool {
        showsContext && details != nil
    }

    var body: some View {
        if showsContext {
            listed
        } else {
            underItsSubject
        }
    }

    // MARK: - On the grades list

    /// Three blocks, the same grammar the education and subject tiles use:
    /// what the record is with its number as the trailing anchor, the context
    /// that places it, and — pushed to the bottom so it lands on one line
    /// across a whole grid row — when it happened and what it counted for.
    private var listed: some View {
        // Zero spacing; the `Spacer` below carries the gap itself, and stack
        // spacing either side of it would apply twice.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                    Text(heading ?? "")
                        .font(ScadeDesign.rowTitle)
                        // One line, where the other two tiles give their
                        // *names* two. A description is a note, not a name:
                        // it runs to 2500 characters, it is often absent
                        // altogether, and a tile that grows to fit one drags
                        // every grade beside it down the grid row. What
                        // doesn't fit is on the grade's own screen.
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(heading ?? "")

                    Spacer(minLength: 0)

                    value
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

            HStack(spacing: ScadeDesign.rowSpacing) {
                whenAndWeight
                Spacer(minLength: 0)
            }
        }
    }

    /// The parents that place the grade, on one line however long their names.
    ///
    /// Two `Text`s rather than one interpolated string so the squeeze falls on
    /// the right one: the education repeats down the whole list and is the
    /// half worth losing, while the subject is what distinguishes this grade
    /// from the one beside it.
    ///
    /// `lineLimit` on the line and not on the `Text`s inside it, because the
    /// separator is a `Text` too: squeezed towards zero width it wrapped, and
    /// a 255-character subject name made the tile a line taller — with each
    /// name already correctly held to one line.
    @ViewBuilder
    private var contextLine: some View {
        HStack(spacing: 0) {
            if showsSubject {
                Text(item.subject.name)
                    .help(item.subject.name)

                Text(" · ")
            }

            Text(item.education.name)
                // Worth reading in full when it doesn't fit: nothing else on
                // the tile carries it.
                .help(item.education.name)

            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .truncationMode(.tail)
    }

    // MARK: - Under its subject

    /// The date leads and the description follows it, rather than the other
    /// way round.
    ///
    /// Every grade has a date; not every grade has a description. Heading the
    /// row with the optional field is what made a column of them ragged —
    /// the date sat on the first line for some rows and the second for
    /// others. This way the two things the eye tracks are always in the same
    /// place and the note is the only thing that varies.
    private var underItsSubject: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                whenAndWeight
                    // Primary, not secondary: here the date is what
                    // identifies the row, not what qualifies it.
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                value
            }

            if let details {
                Text(details)
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
                    // One line. A row is not a paragraph, and the whole
                    // description is one click away on the grade itself —
                    // with a tooltip in the meantime, since a truncated note
                    // is otherwise unreadable without navigating.
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(details)
            }
        }
    }

    // MARK: - Shared parts

    private var value: some View {
        GradeValueLabel(item.grade.value)
            .font(ScadeDesign.value)
            .bold()
    }

    /// When it happened and what it counted for.
    ///
    /// The weight sits in the phrase rather than pinned opposite the date.
    /// §2.5: only the number goes hard right. It was pinned, which is
    /// invisible on a 300pt tile and leaves a word at each end of a row on a
    /// detail card as wide as the window.
    private var whenAndWeight: some View {
        HStack(spacing: 0) {
            Text(item.grade.date.startOfDay(), format: .dateTime.day().month().year())

            // Only when it isn't the default — see
            // `WeightLabel.isMeaningful`. A list where every row read "100%"
            // was the absence of weighting announcing itself.
            if WeightLabel.isMeaningful(item.grade.weight) {
                Text(" · ")
                WeightLabel(item.grade.weight)
            }
        }
        .font(ScadeDesign.rowMeta)
        .foregroundStyle(.secondary)
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

#Preview("Rows under a subject") {
    DetailSection(title: "Grades") {
        DetailCardRow(position: .first) {
            GradeRowView(
                item: PreviewData.gradeItem(id: 1, value: 5.5, weight: 0.5, details: "Schlussprüfung"),
                showsContext: false
            )
        }
        DetailCardRow(position: .middle) {
            GradeRowView(item: PreviewData.gradeItem(id: 2, value: 3.25, details: nil), showsContext: false)
        }
        DetailCardRow(position: .last) {
            GradeRowView(
                item: PreviewData.gradeItem(
                    id: 3,
                    value: 6.0,
                    details: "Schlussprüfung über das gesamte Semester, inklusive der mündlichen Präsentation"
                ),
                showsContext: false
            )
        }
    }
    .padding(ScadeDesign.contentMargin)
}
