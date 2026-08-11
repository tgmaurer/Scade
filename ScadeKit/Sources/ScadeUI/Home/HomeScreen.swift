import ScadeKit
import SwiftUI

/// The dashboard (SPEC §4): one education at a time, optionally one semester.
struct HomeScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = HomeModel()
    @State private var educationFormMode: EducationFormMode?
    @State private var subjectFormMode: SubjectFormMode?
    @State private var gradeFormMode: GradeFormMode?
    @State private var isShowingSettings = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var model = model

        List {
            if let education = model.selectedEducation {
                Section {
                    HomeSummaryHeader(
                        education: education,
                        average: model.average,
                        subjectCount: model.subjects.count,
                        gradeCount: model.gradeCount,
                        semester: model.semester
                    )
                    // The card is figures, not a way through to anything.
                    // Its one control is the education's name (§2.8).
                    .cardRow(.only, highlightsOnHover: false)
                }
                .cardSection()

                ForEach(model.semesters) { semester in
                    HomeSemesterSection(
                        semester: semester,
                        showsGrades: showsGrades,
                        onAddGrade: startAddingGrade
                    )
                }
            }
        }
        .groupedListStyle()
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

            // Where Settings has no section of its own — everywhere but
            // macOS — this is the way in (SPEC-POLISH §2.2).
            if AppSection.showsSettingsSection == false {
                ToolbarItem {
                    Button("Settings", systemImage: "gearshape", action: showSettings)
                        .accessibilityIdentifier(AccessibilityID.Settings.open)
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheet()
        }
        // No `onDismiss` reload on any of these: what a form writes, the
        // observation below already sees.
        .sheet(item: $educationFormMode) { mode in
            EducationFormScreen(mode: mode)
        }
        .sheet(item: $subjectFormMode) { mode in
            SubjectFormScreen(mode: mode)
        }
        .sheet(item: $gradeFormMode) { mode in
            GradeFormScreen(mode: mode)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        // Keyed on the selection, so choosing another education restarts the
        // observation against that one. `HomeModel` relies on this.
        .task(id: model.selectedEducationId) {
            await model.observe(repositories)
        }
    }

    /// §4: a subject's grades are listed under it only in a regular width.
    /// A compact one shows the name and average, and the grades are a tap
    /// away in the subject detail (SPEC-POLISH §2.3).
    private var showsGrades: Bool {
        sizeClass != .compact
    }

    private func startCreatingEducation() {
        educationFormMode = .create
    }

    private func showSettings() {
        isShowingSettings = true
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
