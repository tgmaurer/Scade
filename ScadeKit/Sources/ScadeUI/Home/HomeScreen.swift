import ScadeKit
import SwiftUI

/// The dashboard (SPEC §4): one education at a time, optionally one semester.
struct HomeScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = HomeModel()
    @State private var educationFormMode: EducationFormMode?
    @State private var subjectFormMode: SubjectFormMode?
    @State private var gradeFormMode: GradeFormMode?

    var body: some View {
        @Bindable var model = model

        List {
            if let education = model.selectedEducation {
                HomeSummarySection(
                    education: education,
                    average: model.average,
                    subjectCount: model.subjects.count,
                    gradeCount: model.gradeCount,
                    semester: model.semester
                )

                ForEach(model.subjects) { item in
                    HomeSubjectSection(
                        item: item,
                        education: education,
                        onAddGrade: startAddingGrade
                    )
                }
            }
        }
        .navigationTitle("Home")
        .overlay {
            HomeEmptyState(
                hasEducations: model.educations.isEmpty == false,
                hasSubjects: model.subjects.isEmpty == false,
                isFilteringSemester: model.semester != nil,
                canAddSubject: model.canAddSubject,
                onCreateEducation: startCreatingEducation,
                onCreateSubject: startAddingSubject,
                onClearFilter: { model.semester = nil }
            )
        }
        .toolbar {
            ToolbarItem {
                HomeEducationMenu(
                    educations: model.educations,
                    selection: $model.selectedEducationId
                )
            }

            ToolbarItem {
                HomeSemesterMenu(
                    semester: $model.semester,
                    semesters: model.availableSemesters
                )
                // §4: unavailable until an education is picked.
                .disabled(model.selectedEducation == nil)
            }

            ToolbarItem {
                Button("New Subject", systemImage: "plus", action: startAddingSubject)
                    .disabled(model.canAddSubject == false)
                    .help(
                        model.canAddSubject
                            ? ""
                            : "This education is completed. Reopen it to add a subject."
                    )
            }

            ToolbarItem {
                Button("Reload", systemImage: "arrow.clockwise", action: reload)
            }
        }
        .sheet(item: $educationFormMode, onDismiss: reload) { mode in
            EducationFormScreen(mode: mode)
        }
        .sheet(item: $subjectFormMode, onDismiss: reload) { mode in
            SubjectFormScreen(mode: mode)
        }
        .sheet(item: $gradeFormMode, onDismiss: reload) { mode in
            GradeFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        model.attach(repositories)
        model.load(from: repositories)
    }

    private func startCreatingEducation() {
        educationFormMode = .create
    }

    /// §4: prefilled with the current education, and the filtered semester
    /// when one is active.
    private func startAddingSubject() {
        guard let id = model.selectedEducationId else { return }
        subjectFormMode = .create(educationId: id, semester: model.semester)
    }

    private func startAddingGrade(subjectId: Int64) {
        gradeFormMode = .create(subjectId: subjectId)
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
