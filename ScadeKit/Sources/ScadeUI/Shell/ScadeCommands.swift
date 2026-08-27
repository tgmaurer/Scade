import SwiftUI

#if os(macOS)
import AppKit
#endif

/// The app's menu bar (SPEC-POLISH §1).
///
/// Every shortcut here has a menu item, which is the rule §1.4 sets and the
/// reason this is a `Commands` scene rather than shortcuts hung on the
/// buttons themselves: a shortcut nobody can find is worse than none.
///
/// The context-sensitive ones read `@FocusedValue`, so what `⌘N` makes and
/// what `⌘⌫` deletes is decided by whichever screen is in front — see
/// `ScreenAction`. An item with nothing behind it is shown greyed rather than
/// hidden, so the menu's shape doesn't shift as you move around the app.
public struct ScadeCommands: Commands {
    @FocusedValue(\.newRecord) private var newRecord
    @FocusedValue(\.editRecord) private var editRecord
    @FocusedValue(\.deleteRecord) private var deleteRecord
    @FocusedValue(\.openParent) private var openParent
    @FocusedValue(\.goBack) private var goBack
    @FocusedValue(\.focusSearch) private var focusSearch
    @FocusedValue(\.clearFilters) private var clearFilters
    @FocusedValue(\.selectSection) private var selectSection

    public init() {}

    public var body: some Commands {
        // Replacing rather than adding: the default group is a lone "New
        // Window ⌘N", and ⌘N belongs to the app's content. In an app that
        // makes records rather than documents that's the convention — Notes,
        // Reminders and Things all take it — so New Window moves to ⌘⇧N,
        // beside the ⌘T that now exists.
        CommandGroup(replacing: .newItem) {
            command(newRecord, fallback: "New")
                .keyboardShortcut("n", modifiers: .command)

            #if os(macOS)
            WindowCommands()
            #endif

            Divider()

            command(editRecord, fallback: "Edit")
                .keyboardShortcut("e", modifiers: .command)

            command(deleteRecord, fallback: "Delete")
                .keyboardShortcut(.delete, modifiers: .command)
        }

        CommandGroup(after: .textEditing) {
            command(focusSearch, fallback: "Search")
                .keyboardShortcut("f", modifiers: .command)

            command(clearFilters, fallback: "Clear Filters")
                .keyboardShortcut("f", modifiers: [.shift, .command])
        }

        #if os(macOS)
        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                NSApp.sendAction(
                    #selector(NSSplitViewController.toggleSidebar(_:)),
                    to: nil,
                    from: nil
                )
            }
            .keyboardShortcut("s", modifiers: [.control, .command])
        }
        #endif

        // A menu of its own, the way Finder keeps Go: these are the app's
        // places, and `⌘↑` for the record above this one is the same gesture
        // as Finder's Enclosing Folder.
        CommandMenu("Go") {
            ForEach(Array(AppSection.allCases.enumerated()), id: \.element) { index, section in
                Button(section.title) {
                    selectSection?(section)
                }
                .keyboardShortcut(sectionKey(index), modifiers: .command)
                .disabled(selectSection == nil)
            }

            Divider()

            command(goBack, fallback: "Back")
                // `ö`, not `[`. On a Swiss keyboard `[` is ⌥5 — unreachable
                // as a shortcut — and `ö` sits where a US layout puts `[`,
                // which is why macOS apps answer ⌘ö there. Bound by
                // character, so this is right for the layout this app is
                // used on and wrong for a US one.
                .keyboardShortcut("ö", modifiers: .command)

            command(openParent, fallback: "Enclosing Record")
                .keyboardShortcut(.upArrow, modifiers: .command)
        }
    }

    /// A menu item for a focused action, greyed out where no screen offers
    /// one — `fallback` is the name it wears while that's true.
    private func command(
        _ action: ScreenAction?,
        fallback: LocalizedStringKey
    ) -> some View {
        Button(action?.title ?? fallback) {
            action?()
        }
        .disabled(action == nil)
    }

    /// `⌘1` for the first section and so on. The sections are a fixed short
    /// list, so this can't run out of digits.
    private func sectionKey(_ index: Int) -> KeyEquivalent {
        KeyEquivalent(Character("\(index + 1)"))
    }
}

#if os(macOS)
/// New Tab and New Window.
///
/// Its own view because both need `openWindow` from the environment, which a
/// `Commands` struct can't hold.
private struct WindowCommands: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("New Tab") {
            WindowTabbing.openAsTab {
                openWindow(id: ScadeWindow.main)
            }
        }
        .keyboardShortcut("t", modifiers: .command)

        Button("New Window") {
            openWindow(id: ScadeWindow.main)
        }
        .keyboardShortcut("n", modifiers: [.shift, .command])
    }
}
#endif

/// The app's window identifiers.
public enum ScadeWindow {
    /// The one kind of window there is. Named because `openWindow` needs an
    /// id to open a second one.
    public static let main = "main"
}
