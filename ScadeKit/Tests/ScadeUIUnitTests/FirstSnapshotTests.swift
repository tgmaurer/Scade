import Foundation
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// Nothing is claimed about a screen's contents until the first snapshot has
/// arrived.
///
/// An observation is asynchronous, so every screen is briefly on screen with
/// empty arrays in it. The empty state read that as "there is nothing here"
/// and drew "Nothing to Track Yet" for a frame, so switching sections flashed
/// a false answer before the true one landed (SPEC-POLISH §2.7).
///
/// Both halves are pinned: it starts false, and it does become true — a flag
/// that never flips would hide the empty state forever, which is the same bug
/// wearing the other hat.
@MainActor
struct FirstSnapshotTests {
    /// A database of its own per test, so one test's writes can't be another
    /// test's first snapshot.
    private func makeRepositories() throws -> Repositories {
        Repositories(database: try AppDatabase.inMemory())
    }

    private func makeHomeModel() -> HomeModel {
        let suite = "scade.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return HomeModel(selectionStore: EducationSelectionStore(defaults: defaults))
    }

    /// Runs `observe` until `hasLoaded` turns true, then cancels it.
    ///
    /// Polls rather than awaiting the stream directly: `observe` is the method
    /// the screens call, and going around it would test something the app
    /// doesn't do.
    private func waitForLoad(
        _ hasLoaded: @escaping @MainActor () -> Bool,
        observing: @escaping @Sendable () async -> Void
    ) async throws -> Bool {
        let task = Task { await observing() }
        defer { task.cancel() }

        for _ in 0..<100 {
            if hasLoaded() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return hasLoaded()
    }

    @Test func theDashboardHasLoadedNothingToBeginWith() {
        #expect(makeHomeModel().hasLoaded == false)
    }

    @Test func theDashboardHasLoadedOnceTheFirstSnapshotArrives() async throws {
        let repositories = try makeRepositories()
        let model = makeHomeModel()

        #expect(try await waitForLoad({ model.hasLoaded }) { await model.observe(repositories) })
    }

    @Test func theEducationsListHasLoadedNothingToBeginWith() {
        #expect(EducationListModel().hasLoaded == false)
    }

    @Test func theEducationsListHasLoadedOnceTheFirstSnapshotArrives() async throws {
        let repositories = try makeRepositories()
        let model = EducationListModel()

        #expect(try await waitForLoad({ model.hasLoaded }) { await model.observe(repositories) })
    }

    @Test func theSubjectsListHasLoadedNothingToBeginWith() {
        #expect(SubjectListModel().hasLoaded == false)
    }

    @Test func theSubjectsListHasLoadedOnceTheFirstSnapshotArrives() async throws {
        let repositories = try makeRepositories()
        let model = SubjectListModel()

        #expect(try await waitForLoad({ model.hasLoaded }) { await model.observe(repositories) })
    }

    @Test func theGradesListHasLoadedNothingToBeginWith() {
        #expect(GradeListModel().hasLoaded == false)
    }

    @Test func theGradesListHasLoadedOnceTheFirstSnapshotArrives() async throws {
        let repositories = try makeRepositories()
        let model = GradeListModel()

        #expect(try await waitForLoad({ model.hasLoaded }) { await model.observe(repositories) })
    }
}
