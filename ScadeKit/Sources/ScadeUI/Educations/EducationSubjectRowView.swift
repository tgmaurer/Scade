import ScadeKit
import SwiftUI

/// One of an education's subjects, as listed on the education detail screen.
///
/// Two lines, not three. The old row put the semester, the weight, the grade
/// count and the status on three stacked half-empty lines with a value pinned
/// to the right of each — the same "four lines saying two lines' worth" that
/// §0.1 recorded against the subjects list.
///
/// Carries no padding of its own — `DetailCardRow` supplies it, the same
/// way `cardTile` does on the grids.
///
/// It also read "Semester 4 of 8" and "100%" on every row. The total is one
/// fact about the education and it's in the header above; a weight of 1 is
/// the absence of weighting announcing itself (`WeightLabel.isMeaningful`).
/// Both were the same number repeated down the whole card.
struct EducationSubjectRowView: View {
    let subjectGrades: SubjectGrades

    /// Passed in already computed — the detail screen works it out once per
    /// load rather than once per `body`.
    let average: Double?

    private var subject: Subject { subjectGrades.subject }

    private var semester: String {
        subject.semester.formatted(.number.grouping(.never))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                Text(subject.name)
                    .font(ScadeDesign.rowTitle)

                Spacer(minLength: 0)

                AverageLabel(average)
                    .font(ScadeDesign.value)
                    .bold()
            }

            HStack(alignment: .firstTextBaseline, spacing: ScadeDesign.rowSpacing) {
                // One phrase rather than three fields pinned across the row:
                // §2.5 — what goes hard right is the number, and only the
                // number.
                Text("Semester \(semester) · ^[\(subjectGrades.grades.count) grade](inflect: true)")

                if WeightLabel.isMeaningful(subject.weight) {
                    Text(verbatim: "·")
                    WeightLabel(subject.weight)
                }

                // In the phrase, not pinned opposite it. A card here is as
                // wide as the window, and a badge at the far end of one is
                // the void §2.5 warns about — the tiles can pin it because a
                // tile is 300pt across.
                CompletionBadge(isCompleted: subject.completed)

                Spacer(minLength: 0)
            }
            .font(ScadeDesign.rowSecondary)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DetailSection {
        DetailCardRow(position: .first) {
            EducationSubjectRowView(
                subjectGrades: SubjectGrades(
                    subject: Subject(educationId: 1, name: "Analysis", semester: 2, weight: 1.5),
                    grades: [
                        Grade(subjectId: 1, value: 5.5, date: .today()),
                        Grade(subjectId: 1, value: 3.75, date: .today()),
                    ]
                ),
                average: 4.625
            )
        }

        DetailCardRow(position: .last) {
            EducationSubjectRowView(
                subjectGrades: SubjectGrades(
                    subject: Subject(educationId: 1, name: "Datenbanken", semester: 3),
                    grades: []
                ),
                average: nil
            )
        }
    }
    .padding(ScadeDesign.contentMargin)
}
