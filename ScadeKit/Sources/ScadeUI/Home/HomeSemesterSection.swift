#if !os(macOS)
import ScadeKit
import SwiftUI

/// One semester's subjects, as a section of the dashboard's `List`.
///
/// iOS only. Its swipe action is the only way to add a grade on a phone,
/// where the row shows no chips to press — which is the whole reason the
/// dashboard is still a `List` here and a document of cards on macOS
/// (SPEC-POLISH §2.5). See `HomeScreen.semesterCards` for the other half.
///
/// Grades sit inside their subject's row where there's width for them, rather
/// than as rows of their own beneath it (SPEC-POLISH §2.3, §0.1). On a phone
/// they're dropped entirely: the dashboard answers "how am I doing", and
/// subject detail already lists every grade one tap away.
struct HomeSemesterSection: View {
    let semester: HomeSemester
    let showsGrades: Bool
    let onAddGrade: (Int64) -> Void

    var body: some View {
        Section {
            ForEach(semester.subjects.enumerated(), id: \.element.id) { index, item in
                HomeSubjectRow(item: item, showsGrades: showsGrades) {
                    add(to: item)
                }
                .padding(.vertical, ScadeDesign.rowVerticalPadding)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // §4 hides quick-add once the subject is completed.
                    if item.subject.completed == false, let id = item.subject.id {
                        Button("Add Grade", systemImage: "plus") {
                            onAddGrade(id)
                        }
                        .tint(ScadeDesign.accent)
                    }
                }
                .cardRow(CardRowPosition(index: index, count: semester.subjects.count))
            }
        } header: {
            Text(semester.title)
                .font(ScadeDesign.rowSecondary)
                .bold()
                .textCase(nil)
                .cardSectionHeader()
        }
        .cardSection()
    }

    private func add(to item: HomeSubject) {
        guard let id = item.subject.id else { return }

        onAddGrade(id)
    }
}

#Preview {
    List {
        HomeSemesterSection(
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
#endif
