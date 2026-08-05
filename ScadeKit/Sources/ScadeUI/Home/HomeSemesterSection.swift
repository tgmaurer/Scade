import ScadeKit
import SwiftUI

/// One semester's subjects, as a card.
///
/// Grades are listed under each subject only where there's room for them
/// (SPEC-POLISH §2.3). On a phone the dashboard answers "how am I doing"; a
/// wall of every grade behind every subject answers a different question, and
/// subject detail already lists them all one tap away.
struct HomeSemesterSection: View {
    let semester: HomeSemester
    let education: Education
    let showsGrades: Bool
    let onAddGrade: (Int64) -> Void

    var body: some View {
        Section {
            ForEach(semester.subjects) { item in
                HomeSubjectRow(item: item)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // §4 hides quick-add once the subject is completed.
                        if item.subject.completed == false, let id = item.subject.id {
                            Button("Add Grade", systemImage: "plus") {
                                onAddGrade(id)
                            }
                            .tint(ScadeDesign.accent)
                        }
                    }

                if showsGrades {
                    ForEach(item.grades) { grade in
                        NavigationLink(value: grade) {
                            GradeRowView(
                                item: GradeListItem(
                                    grade: grade,
                                    subject: item.subject,
                                    education: education
                                ),
                                showsContext: false
                            )
                        }
                        .padding(.leading)
                    }
                }
            }
        } header: {
            Text(semester.title)
                .font(ScadeDesign.rowSecondary)
                .textCase(nil)
        }
    }
}

#Preview {
    List {
        HomeSemesterSection(
            semester: HomeSemester(
                semester: 1,
                subjects: [
                    PreviewData.homeSubject(name: "Analysis I"),
                    PreviewData.homeSubject(name: "Lineare Algebra", failing: true),
                ]
            ),
            education: PreviewData.education(),
            showsGrades: false,
            onAddGrade: { _ in }
        )
    }
}
