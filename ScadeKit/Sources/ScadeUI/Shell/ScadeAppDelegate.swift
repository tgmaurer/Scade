#if os(macOS)
import AppKit
import SwiftUI

/// Quits Scade when its last window closes (SPEC-POLISH §1.3).
///
/// Staying alive without a window is the macOS default, and it earns its keep
/// when there is something left to be alive *for*: another document to open,
/// work continuing in the background, a menu bar item, a sync. Scade is none
/// of those. It is one database with a window on top, and a windowless Scade
/// does nothing at all — it sits in the Dock claiming otherwise, and `⌘Q` is
/// a second thing to do after the one that already meant "done".
///
/// It also makes the restore README documents honest. That is a file copy
/// "with the app quit"; closing the window now closes the database rather
/// than merely putting it out of sight.
///
/// **Not `Window` in place of `WindowGroup`.** That terminates on close too,
/// in no code at all, but it does it by forbidding a second window — which
/// would take `⌘⇧N` and the `⌘T` tabs of §1.3 with it. Those are built and
/// wanted. This decides only what happens after the last one closes.
@MainActor
public final class ScadeAppDelegate: NSObject, NSApplicationDelegate {
    public override init() {
        super.init()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        true
    }
}
#endif
