import Foundation

/// The weight quick-picks from SPEC §4, as percentages.
///
/// In the old app these were rows in a `Weight` table, which made them look
/// like data. They aren't — they're a convenience list beside a free numeric
/// field, so they live in the UI where they belong.
enum WeightPreset {
    /// `0` is last and is not one of the old app's picks. It is how "this
    /// doesn't count" is discovered: the number is typeable in the field
    /// beside this, but nobody thinks to try a weight of nothing unless the
    /// list says it is allowed.
    static let percentages: [Double] = [
        100, 90, 87.5, 80, 75, 70, 66.7, 62.5, 60,
        50, 40, 37.5, 33.3, 30, 25, 20, 12.5, 10, 0,
    ]
}
