import SwiftUI

/// The handful of measurements the app doesn't get from the system.
///
/// Deliberately short. SwiftUI's default spacing and padding adapt to Dynamic
/// Type and platform, so anything that can be left to the system is left to
/// the system; only values the system has no opinion about live here.
enum ScadeDesign {
    /// Gap between an inline icon and the text it qualifies — tighter than
    /// the default stack spacing, which is meant for separate elements.
    static let iconTextSpacing: Double = 4

    /// Corner radius for the small filled badges (averages, weights).
    static let badgeCornerRadius: Double = 6

    // MARK: - Colour

    /// The app's accent (SPEC-POLISH §2.1).
    ///
    /// Indigo, chosen for hue distance from the failing-red: a badge below 4
    /// has to read as trouble at a glance, which it can't do if the accent is
    /// the neighbouring hue. The system colour rather than a literal, so it
    /// adapts to light and dark and to increased contrast by itself.
    static let accent = Color.indigo

    // MARK: - Type
    //
    // The ladder from SPEC-POLISH §2.4. Hierarchy comes from size and weight
    // before colour, and every one of these is a system text style, so they
    // scale with Dynamic Type rather than pinning a point size.

    /// The number a screen exists for — the education average on Home.
    static let headlineNumber: Font = .largeTitle.monospacedDigit()

    /// What the eye should land on first in a row.
    static let rowTitle: Font = .headline

    /// Context that qualifies the title: institution, parent, date range.
    static let rowSecondary: Font = .subheadline

    /// Counts, weights, and anything else that's reference rather than
    /// content. `.caption2` is deliberately absent — it's too small to read.
    static let rowMeta: Font = .caption

    /// Grade values and averages wherever they appear. Monospaced digits so a
    /// column of them lines up and doesn't jitter as values change — this app
    /// is mostly columns of numbers.
    static let value: Font = .body.monospacedDigit()

    // MARK: - Surfaces

    /// Corner radius for the card a semester's subjects sit on.
    static let cardCornerRadius: Double = 12
}
