import ScadeKit
import SwiftUI

/// Backs the dashboard.
///
/// The semester filter narrows an already-fetched tree rather than issuing a
/// second query — the subjects and grades are all in hand, and §4 wants the
/// average to follow the filter.
@Observable
final class HomeModel {
    private(set) var educations: [Education] = []
    private(set) var summary: EducationSummary?

    /// Recomputed on every load, education switch and filter change, per §4.
    private(set) var average: Double?
    private(set) var subjects: [HomeSubject] = []

    /// The same subjects, grouped for display (SPEC-POLISH §2.3). Derived
    /// here rather than in `body`, which runs far more often than the data
    /// changes.
    private(set) var semesters: [HomeSemester] = []

    /// No `didSet` refetch: the screen's `task` is keyed on this, so changing
    /// it restarts the observation against the education now chosen. The
    /// `didSet` that *is* here only writes the choice down, so leaving Home
    /// and coming back — or relaunching — returns to it. See
    /// `EducationSelectionStore`.
    var selectedEducationId: Int64? {
        didSet { selectionStore.remember(selectedEducationId) }
    }

    private let selectionStore: EducationSelectionStore

    init(selectionStore: EducationSelectionStore = .shared) {
        self.selectionStore = selectionStore
        // Assigning in `init` doesn't call `didSet`, so restoring the
        // remembered choice doesn't write it straight back.
        selectedEducationId = selectionStore.remembered()
    }

    /// Narrows what's already in hand, so it needs no query of its own.
    var semester: Int? { didSet { recompute() } }

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    var selectedEducation: Education? {
        educations.first { $0.id == selectedEducationId }
    }

    /// The filter is bounded by the education's own semester count (§4), and
    /// stays unavailable until an education is picked.
    var availableSemesters: [Int] {
        guard let education = selectedEducation, education.semesters >= 1 else { return [] }
        return Array(1...education.semesters)
    }

    var gradeCount: Int {
        subjects.reduce(0) { $0 + $1.grades.count }
    }

    var canAddSubject: Bool {
        selectedEducation.map { $0.completed == false } ?? false
    }

    /// Follows the chosen education for as long as the screen is on screen.
    /// See `AppDatabase.observe`.
    func observe(_ repositories: Repositories) async {
        do {
            for try await data in repositories.database.observeHome(educationId: selectedEducationId) {
                apply(data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ data: HomeData) {
        educations = data.educations

        // Default to the newest education, and drop a selection whose
        // education has since been deleted.
        let resolved = data.educations.contains { $0.id == selectedEducationId }
            ? selectedEducationId
            : data.educations.first?.id

        // Only when it actually moves: the screen's task is keyed on this, so
        // assigning something different restarts the observation and a second
        // value is already on its way. Returning on an *unchanged* selection
        // would strand the last education's subjects on screen after it was
        // deleted — nil resolves to nil, so nothing would restart and nothing
        // below would run.
        if resolved != selectedEducationId {
            selectedEducationId = resolved
            return
        }

        summary = data.summary

        // A different education invalidates a semester filter that may not
        // exist there. `didSet` recomputes.
        if let semester, availableSemesters.contains(semester) == false {
            self.semester = nil
            return
        }

        recompute()
    }

    private func recompute() {
        guard let summary else {
            subjects = []
            semesters = []
            average = nil
            return
        }

        let filtered = summary.subjects.filter { semester == nil || $0.subject.semester == semester }
        subjects = filtered.map(HomeSubject.init)
        semesters = HomeSemester.grouping(subjects)
        average = GradeCalculator.educationAverage(of: filtered)
    }
}
