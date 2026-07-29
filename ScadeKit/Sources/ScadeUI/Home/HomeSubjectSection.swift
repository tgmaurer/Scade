import ScadeKit
import SwiftUI

/// One subject on the dashboard, with its grades listed beneath it.
struct HomeSubjectSection: View {
    let item: HomeSubject
    let education: Education
    let onAddGrade: (Int64) -> Void

    var body: some View {
        Section {
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
            }

            if item.grades.isEmpty {
                Text("No grades yet.")
                    .foregroundStyle(.secondary)
            }

            // §4 hides quick-add once the subject is completed.
            if item.subject.completed == false, let id = item.subject.id {
                Button("Add Grade", systemImage: "plus") {
                    onAddGrade(id)
                }
            }
        } header: {
            HomeSubjectHeader(item: item)
        }
    }
}
