import ScadeKit
import SwiftUI

/// One semester's subjects as the rows of a card — the inside of a section,
/// without the section.
///
/// Split out from `HomeSemesterSection` so macOS can spell its `Section` out
/// where `DetailScroll` can see it and pin the header. Everything below that
/// outermost layer can be a view, and this is it.
struct HomeSemesterRows: View {
    let semester: HomeSemester
    let showsGrades: Bool
    let onAddGrade: (Int64) -> Void

    var body: some View {
        ForEach(semester.subjects.enumerated(), id: \.element.id) { index, item in
            DetailCardRow(
                position: CardRowPosition(index: index, count: semester.subjects.count)
            ) {
                HomeSubjectRow(item: item, showsGrades: showsGrades) {
                    add(to: item)
                }
            }
        }
    }

    private func add(to item: HomeSubject) {
        guard let id = item.subject.id else { return }

        onAddGrade(id)
    }
}

#Preview {
    DetailScroll {
        DetailSection {
            HomeSemesterRows(
                semester: HomeSemester(
                    semester: 3,
                    subjects: [
                        PreviewData.homeSubject(name: "Analysis I"),
                        PreviewData.homeSubject(name: "Lineare Algebra", failing: true),
                    ]
                ),
                showsGrades: true,
                onAddGrade: { _ in }
            )
        }
    }
}
