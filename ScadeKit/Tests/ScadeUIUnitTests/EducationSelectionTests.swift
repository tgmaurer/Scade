import Foundation
import Testing
@testable import ScadeUI

/// Remembering which education the dashboard is showing.
///
/// Covered here rather than by a UI test because the only way to choose an
/// education in the app is a `Picker` inside a toolbar `Menu`, which macOS
/// renders as a `menuButton` that XCUITest could not be made to open. What
/// these pin down is the mechanism the screen depends on: the choice survives
/// a model being thrown away and rebuilt, which is what a section switch does.
@MainActor
struct EducationSelectionTests {
    /// A store nothing else can see, so tests can't leak into each other or
    /// into the developer's own preferences.
    private func makeStore() -> EducationSelectionStore {
        let suite = "scade.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return EducationSelectionStore(defaults: defaults)
    }

    @Test func remembersNothingBeforeAnythingIsChosen() {
        #expect(makeStore().remembered() == nil)
    }

    @Test func roundTripsAChoice() {
        let store = makeStore()

        store.remember(7)

        #expect(store.remembered() == 7)
    }

    @Test func forgetsWhenTheChoiceIsCleared() {
        let store = makeStore()
        store.remember(7)

        store.remember(nil)

        #expect(store.remembered() == nil)
    }

    /// The bug this all exists for: `HomeScreen` keeps its model in `@State`
    /// and macOS rebuilds the whole detail column on a section switch, so
    /// leaving Home and coming back used to start from no selection and fall
    /// back to the newest education.
    @Test func aNewModelStartsFromTheRememberedChoice() {
        let store = makeStore()
        store.remember(3)

        let model = HomeModel(selectionStore: store)

        #expect(model.selectedEducationId == 3)
    }

    @Test func choosingAnEducationWritesItDown() {
        let store = makeStore()
        let model = HomeModel(selectionStore: store)

        model.selectedEducationId = 5

        #expect(store.remembered() == 5)
    }

    /// Restoring must not immediately write back — harmless here, but it
    /// would mean `init` had side effects on storage it was only reading.
    @Test func restoringDoesNotOverwriteWhatItRead() {
        let store = makeStore()
        store.remember(9)

        _ = HomeModel(selectionStore: store)

        #expect(store.remembered() == 9)
    }
}
