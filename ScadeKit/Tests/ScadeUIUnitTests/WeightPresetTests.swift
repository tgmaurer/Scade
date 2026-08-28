import Testing

@testable import ScadeUI

@MainActor
@Suite("Weight quick-picks")
struct WeightPresetTests {

    /// The field beside the menu takes any number, so 0 was typeable before
    /// it was offered — and nobody thinks to try a weight of nothing unless
    /// the list says it is allowed. This is the whole discoverability of the
    /// feature, so it is pinned rather than left to a reading of the array.
    @Test("Offers a weight of nothing")
    func offersZero() {
        #expect(WeightPreset.percentages.contains(0))
    }

    /// Descending, so the menu reads from "counts most" down to "counts
    /// nothing" — and 0 is the floor rather than a stray entry in the middle.
    @Test("Runs from the heaviest to the lightest")
    func isDescending() {
        #expect(WeightPreset.percentages == WeightPreset.percentages.sorted(by: >))
        #expect(WeightPreset.percentages.last == 0)
        #expect(WeightPreset.percentages.first == 100)
    }

    @Test("Offers nothing that would be rejected")
    func staysWithinTheRules() {
        #expect(WeightPreset.percentages.allSatisfy { $0 >= 0 })
    }
}
