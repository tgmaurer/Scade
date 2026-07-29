import Foundation

/// The Swiss 1–6 scale, in one place.
///
/// SPEC §3.4 traces a bug in the old app to a `Min=0` bound that had been
/// copied into a form and then diverged from the `[Range(1, 6)]` rule the
/// rest of the app enforced. Every bound lives here so there is nothing to
/// diverge from.
public enum GradingScale {
    /// Valid grade values. `6` is best, `1` is worst.
    public static let range: ClosedRange<Double> = 1.0...6.0

    /// Anything below this fails (Swiss convention: 4 passes).
    public static let passingThreshold = 4.0

    public static func contains(_ value: Double) -> Bool {
        range.contains(value)
    }

    /// Drives the red styling on grades and averages (§3.4).
    public static func isFailing(_ value: Double) -> Bool {
        value < passingThreshold
    }
}
