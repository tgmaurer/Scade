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

    var selectedEducationId: Int64? { didSet { refresh() } }
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

    func load(from repositories: Repositories) {
        do {
            educations = try repositories.educations.all()

            // Default to the newest education, and drop a selection whose
            // education has since been deleted.
            if selectedEducationId == nil
                || educations.contains(where: { $0.id == selectedEducationId }) == false {
                selectedEducationId = educations.first?.id
                // `didSet` did the reload; nothing more to do here.
                return
            }

            reloadSummary(from: repositories)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Stored so `didSet` on the selection can refetch without the view
    /// having to notice.
    private var repositories: Repositories?

    func attach(_ repositories: Repositories) {
        self.repositories = repositories
    }

    private func refresh() {
        // A different education invalidates a semester filter that may not
        // exist there.
        if let semester, availableSemesters.contains(semester) == false {
            self.semester = nil
        }
        guard let repositories else { return }
        reloadSummary(from: repositories)
    }

    private func reloadSummary(from repositories: Repositories) {
        guard let id = selectedEducationId else {
            summary = nil
            recompute()
            return
        }

        do {
            summary = try repositories.educations.summary(id: id)
            recompute()
        } catch {
            errorMessage = error.localizedDescription
        }
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
