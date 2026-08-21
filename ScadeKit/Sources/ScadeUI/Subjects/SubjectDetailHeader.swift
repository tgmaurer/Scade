import ScadeKit
import SwiftUI

/// The subject's identity, as the top card of its detail screen.
///
/// The same shape as `EducationDetailHeader` and for the same reasons (§2.4,
/// "a detail screen is not a table of its fields"): what the record is, with
/// the number the screen exists for beside it, then the context that places
/// it, then what it currently amounts to. It replaces a ladder of seven
/// labelled rows — Average, Education, Institution, Semester, Weight, Grades,
/// Status — of which only two labels were ever doing any work.
///
/// **The education is a button, not a line of text** (§0.1: "detail screens
/// should link to their parents"). A subject only exists inside one, so the
/// way back up is a thing you reach for, not a fact you read; the old app's
/// subject detail had the same link, which is a rare case of it being right.
/// `DetailButton` is the treatment — an ordinary-coloured title that lights
/// under the pointer rather than accent text, which on macOS would promise a
/// web link (§2.8).
struct SubjectDetailHeader: View {
    let summary: SubjectSummary
    let average: Double?

    private var subject: Subject { summary.subject }
    private var education: Education { summary.education }

    private var institution: String? {
        guard let institution = education.institution, institution.isEmpty == false else {
            return nil
        }
        return institution
    }

    /// "Semester 4 of 8", where the tiles say only "Semester 4".
    ///
    /// The total belongs to the education, so on a list of subjects it was the
    /// same number on every row. Here there is one subject and its education
    /// is named right above, which is exactly the place the comparison means
    /// something.
    private var semester: String {
        let position = subject.semester.formatted(.number.grouping(.never))
        let total = education.semesters.formatted(.number.grouping(.never))

        return "Semester \(position) of \(total)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            // Centred, not baseline-aligned: §2.4, two rungs this far apart.
            HStack(alignment: .center, spacing: ScadeDesign.rowSpacing) {
                Text(subject.name)
                    .font(.title2.bold())

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(ScadeDesign.headlineNumber)
            }

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                DetailButton(
                    title: education.name,
                    destination: education,
                    font: ScadeDesign.rowSecondary
                )

                if let institution {
                    // Left where it is rather than folded into the button:
                    // the institution belongs to the education, but pressing
                    // it should not be how you get there — the name is the
                    // control, and a control the width of a whole line is
                    // hard to tell from a paragraph.
                    Text(institution)
                        .font(ScadeDesign.rowSecondary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(institution)
                }

                Spacer(minLength: 0)
            }

            Text(semester)
                .font(ScadeDesign.rowSecondary)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text("^[\(summary.gradeCount) grade](inflect: true)")

                // Printed whatever it is, unlike on a row or a chip. A detail
                // screen is the place with room to be complete, which is the
                // distinction `WeightLabel.isMeaningful` exists to draw.
                WeightLabel(subject.weight)

                // In the phrase, not pinned opposite it — §2.4, and the same
                // reason as the education card: this one is as wide as the
                // window.
                CompletionBadge(isCompleted: subject.completed)

                Spacer(minLength: 0)
            }
            .font(ScadeDesign.rowMeta)
            .foregroundStyle(.secondary)
        }
        // Every fact here is one you might want out of the app. The education
        // is a button and so keeps its own gesture; a drag starting on it
        // does nothing rather than selecting, which is the right trade for
        // the one thing on the card that navigates.
        .textSelection(.enabled)
    }
}

#Preview {
    ScrollView {
        DetailSection {
            DetailSectionText {
                SubjectDetailHeader(
                    summary: SubjectSummary(
                        subject: Subject(educationId: 1, name: "Analysis", semester: 4, weight: 1.5),
                        education: PreviewData.education(),
                        grades: [Grade(subjectId: 1, value: 5.5, date: .today())]
                    ),
                    average: 5.5
                )
            }
        }
        .padding(ScadeDesign.contentMargin)
    }
}
