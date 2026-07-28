import Foundation

/// One number format for the whole app (SPEC §3.3).
///
/// The old app mixed `"0.##"` and `"0.0##"` across views, so the same average
/// could read as `5.3` on one screen and `5.25` on another. Everything
/// numeric goes through here instead.
///
/// The locale is explicit rather than implicit so tests can pin it — the
/// decimal separator is a comma in half of Europe, and a test that assumes
/// otherwise is a test that fails on someone else's machine.
public struct GradeFormatter: Sendable {
    /// Shown wherever an average has no grades behind it, driven by the `nil`
    /// from `GradeCalculator` rather than by a `0` sentinel.
    public static let noDataPlaceholder = "N/A"

    public let locale: Locale

    public init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    /// A grade value or computed average: always two decimal places, e.g.
    /// `5.25`.
    public func value(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(locale))
    }

    /// A computed average, or `"N/A"` when there's nothing to average.
    public func average(_ average: Double?) -> String {
        guard let average else { return Self.noDataPlaceholder }
        return value(average)
    }

    /// A weight multiplier as a percentage: `1.0` reads as `100%`, `0.625` as
    /// `62.5%`.
    ///
    /// Storage keeps the multiplier; only the display is a percentage. Up to
    /// one decimal place, which covers the quick-pick presets in §4 (`66.7%`,
    /// `37.5%`, `12.5%`) without printing `100.0%` for the common case.
    public func weight(_ multiplier: Double) -> String {
        multiplier.formatted(.percent.precision(.fractionLength(0...1)).locale(locale))
    }
}
