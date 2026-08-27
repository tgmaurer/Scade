import ScadeKit
import SwiftUI

/// The grade's identity, as the top card of its detail screen.
///
/// The same shape as the education and subject headers (§2.4, "a detail
/// screen is not a table of its fields"), and it replaces the same thing: a
/// ladder of nine labelled rows across three sections — Grade, Weight, Date,
/// then the subject's Name/Semester/Status and the education's
/// Name/Institution/Status — with a hairline between every one.
///
/// **Most of those were facts about other records.** A grade's screen showed
/// its subject's completion state and its education's institution, both a
/// level removed from anything a grade is, and each of them one press away on
/// the record that owns it. What's left is what a grade actually is: a
/// number, a day, what it counted for, and where it belongs.
///
/// **The date heads it, not the description.** A grade has no name; the
/// description is optional (SPEC §3.4) and runs to 2500 characters. The date
/// is the one field every grade has, it can't grow, and it's what the row
/// under a subject leads with too — so the record reads the same way in both
/// places. The description gets a card of its own, like an education's and a
/// subject's.
///
/// **Both parents are buttons** (§0.1, "detail screens should link to their
/// parents"). This is the bottom of the chain, so it's the screen with the
/// most to link back to: grade → subject → education.
struct GradeDetailHeader: View {
    let item: GradeListItem

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            // Centred, not baseline-aligned: §2.4, two rungs this far apart.
            HStack(alignment: .center, spacing: ScadeDesign.rowSpacing) {
                Text(item.grade.date.startOfDay(), format: .dateTime.day().month().year())
                    .font(.title2.bold())

                Spacer(minLength: 0)

                GradeValueLabel(item.grade.value)
                    .font(ScadeDesign.headlineNumber)
            }

            // A separator between two buttons, and the gap either side of it
            // is deliberate: `DetailButton` draws its hover wash 8pt beyond
            // its text, so a tighter line would light the separator along
            // with the name.
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                DetailButton(
                    title: item.subject.name,
                    destination: item.subject,
                    font: ScadeDesign.rowSecondary
                )

                Text(verbatim: "·")
                    .font(ScadeDesign.rowSecondary)
                    .foregroundStyle(.secondary)

                DetailButton(
                    title: item.education.name,
                    destination: item.education,
                    font: ScadeDesign.rowSecondary
                )

                Spacer(minLength: 0)
            }

            // Labelled, unlike everywhere else this appears. §2.4 drops a
            // label where the value says what it is, and "100%" alone on a
            // line does not — a percentage of what? On a row it's read
            // alongside the date and a grade count, which supplies the
            // context this line hasn't got.
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.iconTextSpacing) {
                Text("Weight")
                WeightLabel(item.grade.weight)

                Spacer(minLength: 0)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
        // The two parents keep their own gesture, so a drag that starts on
        // one navigates rather than selects. Everything else here is a fact
        // worth getting out of the app.
        .textSelection(.enabled)
    }
}

#Preview {
    ScrollView {
        DetailSection {
            DetailSectionText {
                GradeDetailHeader(
                    item: PreviewData.gradeItem(value: 5.5, weight: 0.5, details: "Schlussprüfung")
                )
            }
        }
        .padding(ScadeDesign.contentMargin)
    }
}
