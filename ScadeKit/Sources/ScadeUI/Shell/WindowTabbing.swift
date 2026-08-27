#if os(macOS)
import AppKit
import SwiftUI

/// Makes `⌘T` produce a tab where `⌘⇧N` produces a window.
///
/// macOS offers a New Tab command of its own only when something in the
/// responder chain implements `newWindowForTab(_:)`, which SwiftUI's
/// `WindowGroup` doesn't — which is why `⌘T` did nothing at all, while the
/// Window menu already carried Show Next Tab and Merge All Windows. Tabbing
/// was available the whole time; nothing could start it.
///
/// So the app starts it: note which window the new one should join, ask
/// SwiftUI to open it, and add it to that window's tab group when it appears.
/// The note is cleared by the window that claims it, so it can't leak into
/// the next `⌘⇧N`.
@MainActor
enum WindowTabbing {
    private static var host: NSWindow?

    /// Opens a window that should arrive as a tab of the current one.
    static func openAsTab(using open: () -> Void) {
        host = NSApp.keyWindow
        open()
    }

    /// Called by every window as it appears — including the first at launch,
    /// where there is no host and this does nothing.
    static func adopt(_ window: NSWindow) {
        guard let host, host !== window else { return }
        Self.host = nil
        host.addTabbedWindow(window, ordered: .above)
        window.makeKeyAndOrderFront(nil)
    }
}

/// Hands each window to `WindowTabbing` as it appears.
struct WindowTabReader: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { WindowFinder() }

    func updateNSView(_ view: NSView, context: Context) {}

    /// A view rather than a look at `view.window` in `updateNSView`: that
    /// runs before the view has been put in a window — measured, `window` is
    /// nil on the first pass — so the window has to be caught as it arrives.
    private final class WindowFinder: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            WindowTabbing.adopt(window)
        }
    }
}
#endif
