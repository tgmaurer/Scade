import ScadeKit
import SwiftUI

/// The education's identity, as the top card of its detail screen.
///
/// It was a ladder of eight `LabeledContent` rows — Average, Institution,
/// Starts, Ends, Semesters, Subjects, Grades, Status — each the same size as
/// the last, with a hairline between every one. That is precisely the failure
/// §2.5 names, and it was GradeMaster's detail screen reproduced rather than
/// improved on: "a hairline between every label and value".
///
/// **Those were never eight facts worth eight rows.** They are one paragraph
/// of identity, so the labels go and the values carry themselves: an
/// institution reads as an institution, a date range as a date range, "8
/// semesters" as a count. What's left is the §2.4 ladder — the number the
/// screen exists for at the top, the name beside it, and everything else
/// stepped down beneath.
///
/// Deliberately the same shape as `HomeSummaryHeader`, which shows the same
/// education. Two screens showing one record should look like they are.
///
/// A view of its own rather than a property of the section, so it can be
/// rendered and measured — a `Section` renders no more headlessly than a
/// `List` does.
struct EducationDetailHeader: View {
    let summary: EducationSummary
    let average: Double?

    private var education: Education { summary.education }

    private var institution: String? {
        guard let institution = education.institution, institution.isEmpty == false else {
            return nil
        }
        return institution
    }

    /// The full span, not the years the tiles show. A tile has one line for
    /// the whole record; a detail screen is where the exact dates live.
    ///
    /// No `lineLimit` and no `fixedSize`, deliberately. Squeezed — a phone at
    /// an accessibility text size — a plain `Text` wraps at the dash and
    /// keeps both dates whole. Pinning it would truncate instead, and
    /// "Aug 1, 2023 – Jul…" is not a date range: the half that goes is the
    /// half you opened the screen for.
    ///
    /// Internal so it can be measured on its own. Measured inside the whole
    /// header it can't be: everything else on the card wraps as the width
    /// drops too, so the header is taller at a narrow width whether this
    /// wraps or truncates, and a `lineLimit` on it looked like a passing
    /// test.
    var dateRange: some View {
        Text(
            "\(education.startDate.startOfDay(), format: .dateTime.day().month().year()) – \(education.endDate.startOfDay(), format: .dateTime.day().month().year())"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            // Centred, not baseline-aligned: §2.4: a shared baseline between
            // two rungs this far apart pins the name's bottom to the number's
            // and leaves all the slack above it.
            HStack(alignment: .center, spacing: ScadeDesign.rowSpacing) {
                // Repeated from the navigation title deliberately. macOS
                // draws that title small, in chrome, where it reads as the
                // window's label rather than the record's — and the
                // institution and dates below need something to hang from.
                Text(education.name)
                    .font(.title2.bold())

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(ScadeDesign.headlineNumber)
            }

            if let institution {
                Text(institution)
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)
            }

            dateRange
                .font(ScadeDesign.rowSecondary)
                .foregroundStyle(.secondary)

            // The badge stays in the phrase rather than being pinned to the
            // trailing edge, which is what the tiles do and what would be
            // wrong here. §2.5: only the number goes hard right, because
            // anything else leaves a word at each end of the row and a void
            // between them — invisible on a 300pt tile, glaring on a card as
            // wide as the window.
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text(
                    "^[\(education.semesters) semester](inflect: true) · ^[\(summary.subjectCount) subject](inflect: true) · ^[\(summary.gradeCount) grade](inflect: true)"
                )

                CompletionBadge(isCompleted: education.completed)

                Spacer(minLength: 0)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
        // No padding of its own. `DetailSectionText` supplies the card's,
        // evenly on all four sides; the vertical padding that used to be here
        // was a `List` row's breathing room, and once the screen stopped
        // being a `List` it only stacked on top of the card's — 18 above and
        // below against 14 at the sides.
        // Every fact on this card is one you might want out of the app — an
        // institution's full name into a form, a date into a calendar, the
        // average into a message. Safe to enable here and not on the subject
        // rows below: this card is inert, while a row is a link, and a drag
        // that selects text is a drag that doesn't open anything (§2.8).
        //
        // Only works because the screen is no longer a `List` — see
        // `DetailSection`.
        .textSelection(.enabled)
    }}

#Preview {
    List {
        EducationDetailHeader(
            summary: EducationSummary(education: PreviewData.education(), subjects: []),
            average: 5.25
        )
        .cardRow(.only, highlightsOnHover: false)
    }
    .groupedListStyle()
}
