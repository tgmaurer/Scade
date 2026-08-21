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

    /// A symbol standing in for a word inside a chip-sized control.
    ///
    /// Sized with the values it sits among rather than with the metadata,
    /// because it's the control in that run, not a footnote to it. Semibold
    /// because a `plus` is thin strokes and no counters — at `.caption` weight
    /// it reads as a speck next to solid digits.
    static let chipGlyph: Font = .body.weight(.semibold)

    // MARK: - Surfaces

    /// Corner radius for the card a semester's subjects sit on.
    static let cardCornerRadius: Double = 12

    /// Inside a card tile, between its content and its edge. Larger than a
    /// row's, because a tile is a card in its own right rather than one
    /// stripe of a stack — the fill has to read as a container around the
    /// content, not a highlight behind it.
    static let cardTilePadding: Double = 14

    /// Between tiles in a card grid, across and down.
    ///
    /// Deliberately smaller than `contentMargin`: the gap that separates two
    /// tiles from each other must read as narrower than the one that holds
    /// them off the window, or the grid stops looking like one group.
    static let cardGridSpacing: Double = 12

    /// The narrowest a card tile may be before the grid drops a column.
    ///
    /// Set by the top line, which has to hold a name and an average side by
    /// side: below this the name starts truncating on ordinary titles.
    static let minimumCardWidth: Double = 300

    /// The most columns a card grid will use, however wide the window gets.
    ///
    /// Past three, tiles are narrow enough that the eye scans a field of
    /// boxes instead of reading a short list, and the reason for the grid —
    /// seeing every education at once — is already served at two or three.
    static let maximumCardColumns: Int = 3

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

    /// The label column in front of a form's free-text field.
    ///
    /// macOS's grouped `Form` splits a labelled row roughly in half, which
    /// starts a name in the middle of the sheet with a stretch of nothing in
    /// front of it. A label column puts the text where a form's text belongs:
    /// just after the word naming it, and in the same place on every row.
    static let formLabelWidth: Double = 96

    /// Inside a grade chip, to the left and right of its value.
    static let chipPadding: Double = 8

    /// A grade chip's height, and with it the tallest thing a subject row can
    /// contain. Stated rather than left to the chip's padding so the row
    /// height below can be derived from it instead of guessed to match.
    static let chipHeight: Double = 22

    /// How far a card's internal divider is held back from its edges, so it
    /// reads as a line *within* the card rather than a cut across it.
    static let cardDividerInset: Double = 12


    // MARK: - Pointer
    //
    // macOS has a pointer and the app should answer it (SPEC-POLISH §2.8).

    /// How far a hover highlight reaches past the text it sits behind, where
    /// the control has no padding of its own to fill.
    static let hoverInset: Double = 3

    /// The fill a control carries at rest, where it carries one at all.
    ///
    /// Computed rather than stored: these are `AnyShapeStyle`, and a stored
    /// one would be shared mutable state as far as the compiler is concerned.
    static var controlFill: AnyShapeStyle { AnyShapeStyle(.fill.quaternary) }

    /// And under the pointer. Two steps up the hierarchy rather than one —
    /// at one step the change was there but easy to miss, which is no use for
    /// a cue whose whole job is to be noticed before anything is clicked.
    static var controlHoverFill: AnyShapeStyle { AnyShapeStyle(.fill.secondary) }

    /// The wash over a hovered row. Deliberately fainter than a control's:
    /// it answers "where am I", not "this is clickable", and a row-wide
    /// highlight as strong as a button's would drown the button inside it.
    static var rowHoverFill: AnyShapeStyle { AnyShapeStyle(.fill.quaternary) }

    /// Long enough not to snap, short enough not to lag the pointer. The one
    /// animation in the app that isn't explaining a change (§2.7).
    static let hoverDuration: Double = 0.12

    /// The smallest a control may be where it's hit with a finger, from the
    /// HIG. Stated only because the dashboard's rows are sized for a pointer
    /// and would otherwise fall under it.
    static let touchTargetHeight: Double = 44

    /// Between a scroll view's content and the window edge. macOS `List`
    /// gives almost none by itself, which is what makes a window look like
    /// the content is falling out of it.
    static let contentMargin: Double = 20

    /// The macOS sidebar's width — fixed, not a starting point.
    ///
    /// Passed to `navigationSplitViewColumnWidth(_:)` as a single value, which
    /// also removes the resize handle. Widening it would show nothing a narrow
    /// one doesn't: five fixed rows of a word each.
    static let sidebarWidth: Double = 150


    /// How wide the macOS Settings window is.
    ///
    /// Fixed, like the sidebar: the form is read top to bottom and lays out
    /// no differently when it's wider, so dragging its edge would achieve
    /// nothing. Wide enough for the longest answer in the About section to
    /// hold a sensible line length.
    static let settingsWindowWidth: Double = 460

    /// The least height the Settings window opens at.
    ///
    /// A floor rather than a size: Appearance, Backup and Data fit inside it,
    /// and the About section — four questions and their answers — is longer
    /// than any settings window should be, so it scrolls.
    static let settingsWindowHeight: Double = 560

    /// The narrowest the macOS window may become.
    ///
    /// A floor rather than a responsive layout: below this the dashboard's
    /// name, grades and average genuinely cannot coexist on one row, and
    /// designing for a window nobody uses costs more than it returns.
    static let minimumWindowWidth: Double = 740
    static let minimumWindowHeight: Double = 400
}
