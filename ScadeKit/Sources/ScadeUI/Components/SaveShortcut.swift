import SwiftUI

extension View {
    /// `⌘↩` saves the form from anywhere inside it.
    ///
    /// Return alone saves too — a sheet's confirmation button is its default
    /// button — but not from the description, where Return belongs to the
    /// text (§2.4). This is the key that always means *finish*, whichever
    /// field the cursor is in.
    ///
    /// It's a second, invisible button rather than a shortcut on Save
    /// itself, because giving Save an explicit `keyboardShortcut` **takes
    /// away** the default-button role `confirmationAction` granted it:
    /// measured, with the shortcut attached directly, `⌘↩` saved and plain
    /// Return in the name field did nothing at all.
    func saveShortcut(_ save: @escaping () -> Void) -> some View {
        background {
            Button("Save", action: save)
                .keyboardShortcut(.return, modifiers: .command)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }
}
