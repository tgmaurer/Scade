import SwiftUI

/// The handful of measurements the app doesn't get from the system.
///
/// Deliberately short. SwiftUI's default spacing and padding adapt to Dynamic
/// Type and platform, so anything that can be left to the system is left to
/// the system; only values the system has no opinion about live here.
/// `nonisolated` because these are plain constants with no actor affinity —
/// the package defaults to `MainActor`, and a `Layout` conformance is
/// nonisolated, so tokens used from one couldn't be reached otherwise.
nonisolated enum ScadeDesign {
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
    /// the neighbouring hue.
    ///
    /// **Defined in `App/Assets.xcassets/AccentColor.colorset`, not here.** The
    /// asset catalog is the only place that reaches everything: the app icon
    /// tint, the OS's own chrome, and any AppKit/UIKit control SwiftUI doesn't
    /// draw. A literal in this file would colour the view hierarchy and
    /// nothing else. This property reads whatever the catalog defines, so
    /// there's one source of truth and changing the hue is a one-file edit.
    ///
    /// The catalog carries a light and a dark variant, which is the other
    /// thing a code literal can't express without branching on the appearance.
    ///
    /// Package previews render this as the *system* accent, since they have no
    /// app target to read the catalog from. Only previews; the app is correct.
    static let accent = Color.accentColor

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

    // MARK: - Rhythm
    //
    // SwiftUI's defaults are tuned for forms, not for dense data rows, so
    // these few are stated. Everything else still comes from the system.

    /// Breathing room above and below a list row's content.
    static let rowVerticalPadding: Double = 6

    /// Gap between the distinct parts of a row — name, content, trailing
    /// value. Wider than stack spacing, because these are separate columns
    /// rather than one phrase.
    static let rowSpacing: Double = 12

    /// How much room a subject's name is guaranteed on the dashboard, so the
    /// grades that follow it line up down the screen instead of starting at a
    /// different place on every row.
    static let subjectColumnWidth: Double = 160

    /// Inside a grade chip, around its value.
    static let chipPadding: Double = 8

    /// Between a scroll view's content and the window edge. macOS `List`
    /// gives almost none by itself, which is what makes a window look like
    /// the content is falling out of it.
    static let contentMargin: Double = 20

    /// The narrowest the macOS window may become.
    ///
    /// A floor rather than a responsive layout: below this the dashboard's
    /// name, grades and average genuinely cannot coexist on one row, and
    /// designing for a window nobody uses costs more than it returns.
    static let minimumWindowWidth: Double = 880
    static let minimumWindowHeight: Double = 560
}
