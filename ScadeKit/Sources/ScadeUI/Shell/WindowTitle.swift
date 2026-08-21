#if os(macOS)
import SwiftUI

extension View {
    /// Puts the app's name in front of whatever the window is called.
    ///
    /// On macOS `navigationTitle` names the window *and* draws the toolbar's
    /// title, and those two want different strings: the toolbar says
    /// "Subjects", because you're already inside the app, and the window says
    /// "Scade – Subjects", because the Window menu, a window tab, Mission
    /// Control and ⌘` all list it beside other apps' windows, where
    /// "Subjects" on its own says nothing about whose. No API separates the
    /// two.
    ///
    /// So the window's copy is rewritten after the fact. **Writing it once,
    /// deferred by a runloop turn, does not work** — measured: the title
    /// stays exactly what `navigationTitle` set, because SwiftUI writes it
    /// again on its own schedule and wins whichever hop you pick. Observing
    /// it and re-prefixing is the version that holds.
    ///
    /// Pass `nil` to leave the title alone — and to take a prefix already
    /// there back off. A pushed detail screen is titled after the record it
    /// shows, and "Scade – Informatiker EFZ" over a card that says
    /// *Informatiker EFZ* in bold is the app's name interrupting the one
    /// thing on screen that isn't already obvious. The prefix earns its place
    /// at the top level, where the title is a section name that could belong
    /// to any app.
    func windowTitlePrefix(_ prefix: String?) -> some View {
        background(WindowTitleKeeper.Attachment(prefix: prefix))
    }
}

/// Keeps `NSWindow.title` prefixed, however often SwiftUI rewrites it.
private final class WindowTitleKeeper: NSObject {
    /// What the prefix and the title are joined by. An en dash, matching the
    /// ranges elsewhere in the app.
    private static let separator = " – "

    private var observation: NSKeyValueObservation?
    private var prefix: String?

    func attach(to window: NSWindow, prefix: String?) {
        self.prefix = prefix
        apply(to: window)

        guard observation == nil else { return }
        observation = window.observe(\.title, options: [.new]) { [weak self] window, _ in
            self?.apply(to: window)
        }
    }

    /// Re-entrant by design: setting the title fires the observation again,
    /// and the checks here are what stop it the second time round.
    private func apply(to window: NSWindow) {
        guard window.title.isEmpty == false else { return }

        guard let prefix else {
            // Whatever was prefixed on the way in comes back off on the way
            // out — otherwise popping to a section would leave the record's
            // name wearing it.
            if let bare = strippedOfAnyPrefix(window.title) {
                window.title = bare
            }
            return
        }

        let full = prefix + Self.separator
        guard window.title.hasPrefix(full) == false else { return }

        window.title = full + window.title
    }

    /// The title with an `X – ` prefix removed, or nil if there wasn't one.
    private func strippedOfAnyPrefix(_ title: String) -> String? {
        guard let range = title.range(of: Self.separator) else { return nil }
        return String(title[range.upperBound...])
    }

    /// The view that finds the window. There is no other way to reach it.
    ///
    /// It has to be told when it *gains* one rather than asked for it:
    /// `updateNSView` runs once, before the view is in the hierarchy, and
    /// `view.window` is nil there — measured, and the reason the first
    /// version of this silently did nothing at all.
    struct Attachment: NSViewRepresentable {
        let prefix: String?

        func makeCoordinator() -> WindowTitleKeeper { WindowTitleKeeper() }

        func makeNSView(context: Context) -> WindowFinder {
            let view = WindowFinder(frame: .zero)
            view.onWindow = { [prefix] window in
                context.coordinator.attach(to: window, prefix: prefix)
            }
            return view
        }

        func updateNSView(_ view: WindowFinder, context: Context) {
            guard let window = view.window else { return }
            context.coordinator.attach(to: window, prefix: prefix)
        }
    }

    final class WindowFinder: NSView {
        var onWindow: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            guard let window else { return }
            onWindow?(window)
        }
    }
}
#endif
