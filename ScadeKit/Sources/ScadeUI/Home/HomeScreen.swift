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

        content
        .navigationTitle("Home")
        // The dashboard's own two commands (SPEC-POLISH §1.2). There is no
        // search here to focus.
        .focusedSceneValue(\.newRecord, newSubjectAction)
        .focusedSceneValue(\.clearFilters, clearFiltersAction)
        .overlay {
            // Not until the first snapshot has arrived: see
            // `hasLoaded`.
            if model.hasLoaded {
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

            // Where there's no menu bar to keep Settings in, this is the way
            // in (SPEC-POLISH §2.2). macOS opens its own window from the app
            // menu instead — see `SettingsWindow`.
            #if !os(macOS)
            ToolbarItem {
                Button("Settings", systemImage: "gearshape", action: showSettings)
                    .accessibilityIdentifier(AccessibilityID.Settings.open)
            }
            #endif
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

    /// macOS: a document of cards. iOS: a `List`, for its swipe actions.
    ///
    /// **macOS is deliberately not a `List` any more**, and this is a bug fix
    /// rather than a preference. A macOS `List` decides a row's height once
    /// and does not re-measure it, which showed up here twice:
    ///
    /// - Filtering to one semester adds a line to the summary card, and the
    ///   row it sat in kept its old height, so the new line was cut in half.
    /// - Launching on a non-Retina display gave *every* row roughly half the
    ///   height it needed, clipping each one mid-word. Dragging the window to
    ///   a Retina display and back fixed it, which is what a stale cached
    ///   height looks like from the outside.
    ///
    /// Neither is reachable from a `ScrollView`: a `VStack` measures its
    /// content on every layout pass. The cards are the same `DetailSection`
    /// and `DetailCardRow` the detail screens are built from, so this also
    /// leaves one card in the app rather than a `List` lookalike beside it.
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        DetailScroll {
            if let education = model.selectedEducation {
                DetailSection {
                    DetailSectionText {
                        summary(of: education)
                    }
                }
            }

            semesterCards
        }
        #else
        List {
            if let education = model.selectedEducation {
                Section {
                    summary(of: education)
                        // The card is figures, not a way through to anything.
                        // Its one control is the education's name (§2.8).
                        .cardRow(.only, highlightsOnHover: false)
                }
                .cardSection()

                semesterCards
            }
        }
        .groupedListStyle()
        #endif
    }

    /// One card per semester.
    ///
    /// The macOS branch spells the `Section` out here rather than wrapping it
    /// in a view of its own, and that isn't a style choice: `DetailScroll`
    /// pins section headers, and a `LazyVStack` pins only a `Section` it can
    /// see — one hidden inside a custom `View` is invisible to it and doesn't
    /// pin. The rows *inside* the section are a view, because only the
    /// outermost layer is subject to this.
    @ViewBuilder
    private var semesterCards: some View {
        #if os(macOS)
        ForEach(model.semesters) { semester in
            DetailSection(title: semester.title) {
                HomeSemesterRows(
                    semester: semester,
                    showsGrades: showsGrades,
                    onAddGrade: startAddingGrade
                )
            }
        }
        #else
        ForEach(model.semesters) { semester in
            HomeSemesterSection(
                semester: semester,
                showsGrades: showsGrades,
                onAddGrade: startAddingGrade
            )
        }
        #endif
    }

    private func summary(of education: Education) -> some View {
        HomeSummaryHeader(
            education: education,
            average: model.average,
            subjectCount: model.subjects.count,
            gradeCount: model.gradeCount,
            semester: model.semester
        )
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

    /// `nil` where §4 disables the toolbar button — a completed education
    /// takes no new subjects.
    private var newSubjectAction: ScreenAction? {
        guard model.canAddSubject else { return nil }
        return ScreenAction("New Subject", perform: startAddingSubject)
    }

    /// The semester picker is the only filter here; the education above it
    /// is a choice of what to show, not a narrowing of it.
    private var clearFiltersAction: ScreenAction? {
        guard model.semester != nil else { return nil }
        return ScreenAction("Clear Filters") { model.semester = nil }
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
