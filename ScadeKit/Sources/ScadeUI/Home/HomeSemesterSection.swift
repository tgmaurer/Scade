import ScadeKit
import SwiftUI

/// One semester's subjects, as a card.
///
/// Grades sit inside their subject's row where there's width for them, rather
/// than as rows of their own beneath it (SPEC-POLISH §2.3, §0.1). On a phone
/// they're dropped entirely: the dashboard answers "how am I doing", and
/// subject detail already lists every grade one tap away.
///
/// Forks the way `HomeScreen` does, and for the same reason: a macOS `List`
/// row keeps whatever height it was first given, so the card is assembled
/// from `DetailSection` there. iOS keeps the `List` — its swipe actions are
/// the only way to add a grade on a phone, where the row shows no chips to
/// press.
struct HomeSemesterSection: View {
    let semester: HomeSemester
    let showsGrades: Bool
    let onAddGrade: (Int64) -> Void

    var body: some View {
        #if os(macOS)
        DetailSection(title: semester.title) {
            ForEach(semester.subjects.enumerated(), id: \.element.id) { index, item in
                DetailCardRow(position: position(of: index)) {
                    row(for: item)
                }
            }
        }
        #else
        Section {
            ForEach(semester.subjects.enumerated(), id: \.element.id) { index, item in
                row(for: item)
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
                    .cardRow(position(of: index))
            }
        } header: {
            Text(semester.title)
                .font(ScadeDesign.rowSecondary)
                .bold()
                .textCase(nil)
                .cardSectionHeader()
        }
        .cardSection()
        #endif
    }

    private func position(of index: Int) -> CardRowPosition {
        CardRowPosition(index: index, count: semester.subjects.count)
    }

    private func row(for item: HomeSubject) -> some View {
        HomeSubjectRow(item: item, showsGrades: showsGrades) {
            add(to: item)
        }
    }

    private func add(to item: HomeSubject) {
        guard let id = item.subject.id else { return }

        onAddGrade(id)
    }
}

#Preview {
    ScrollView {
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
        .padding(ScadeDesign.contentMargin)
    }
}
