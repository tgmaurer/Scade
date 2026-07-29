import SwiftUI

/// What the dashboard shows when there's nothing to summarise.
struct HomeEmptyState: View {
    let hasEducations: Bool
    let hasSubjects: Bool
    let isFilteringSemester: Bool
    let canAddSubject: Bool
    let onCreateEducation: () -> Void
    let onCreateSubject: () -> Void
    let onClearFilter: () -> Void

    var body: some View {
        if hasEducations == false {
            ContentUnavailableView {
                Label("Nothing to Track Yet", systemImage: "graduationcap")
            } description: {
                Text("Add an education to get started.")
            } actions: {
                Button("New Education", systemImage: "plus", action: onCreateEducation)
            }
        } else if hasSubjects == false, isFilteringSemester {
            ContentUnavailableView {
                Label("Nothing This Semester", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("This education has no subjects in the filtered semester.")
            } actions: {
                Button("Show All Semesters", action: onClearFilter)
            }
        } else if hasSubjects == false {
            ContentUnavailableView {
                Label("No Subjects", systemImage: "books.vertical")
            } description: {
                if canAddSubject {
                    Text("Add a subject to this education to start recording grades.")
                } else {
                    Text("This education is completed. Reopen it to add a subject.")
                }
            } actions: {
                if canAddSubject {
                    Button("New Subject", systemImage: "plus", action: onCreateSubject)
                }
            }
        }
    }
}
