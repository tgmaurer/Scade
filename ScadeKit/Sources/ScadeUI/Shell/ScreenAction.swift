import SwiftUI

/// Something the screen on top can do, offered to the menu bar.
///
/// A menu command lives outside the view hierarchy and can't reach a screen's
/// state, so the screen hands its action *up* instead — through
/// `focusedSceneValue`, which publishes only while that screen is the one in
/// front. Nothing is stored anywhere: when the screen goes, so does the
/// action, and the menu item greys out on its own. That's the difference
/// between this and a shared selection holder, which the app would have to
/// keep correct by hand.
///
/// The name travels with the action because one command means different
/// things in different places: `⌘N` is "New Grade" on a subject and "New
/// Subject" on an education, and a menu item reading "New" on both would be
/// saying less than it knows.
/// **Deliberately not `Equatable`.** It was, briefly, comparing an id the
/// caller passed in — and the commands that never changed theirs silently
/// stopped working: SwiftUI took the equal value as no change and kept the
/// *first* action it was ever given for that key, captured from a body pass
/// whose state was long gone. The menu item was enabled, named correctly,
/// and did nothing at all when chosen. Without the conformance every pass
/// replaces the action, which is what a value closing over a screen's state
/// needs.
struct ScreenAction {
    let title: LocalizedStringKey

    private let perform: () -> Void

    init(_ title: LocalizedStringKey, perform: @escaping () -> Void) {
        self.title = title
        self.perform = perform
    }

    func callAsFunction() {
        perform()
    }
}

extension FocusedValues {
    /// `⌘N` — create the kind of record this screen makes.
    @Entry var newRecord: ScreenAction?

    /// `⌘E` — edit the record on screen.
    @Entry var editRecord: ScreenAction?

    /// `⌘⌫` — delete the record on screen, through its usual confirmation.
    @Entry var deleteRecord: ScreenAction?

    /// `⌘↑` — open the record this one belongs to.
    @Entry var openParent: ScreenAction?

    /// `⌘ö` — pop the navigation stack.
    @Entry var goBack: ScreenAction?

    /// `⌘F` — put the cursor in the search field.
    @Entry var focusSearch: ScreenAction?

    /// `⌘⇧F` — drop every filter on this screen.
    @Entry var clearFilters: ScreenAction?

    /// `⌘1`–`⌘4` — show a section. Published by the shell, not a screen.
    @Entry var selectSection: SectionSelector?
}

/// The shell's "show this section" hook, in a named type because a bare
/// closure can't be a focused value.
struct SectionSelector {
    private let select: (AppSection) -> Void

    init(select: @escaping (AppSection) -> Void) {
        self.select = select
    }

    func callAsFunction(_ section: AppSection) {
        select(section)
    }
}
