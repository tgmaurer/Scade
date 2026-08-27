#if os(macOS)
import AppKit
import Foundation

/// Remembers where backups go, across launches.
///
/// A sandboxed app can reach a folder only after the user has picked it, and
/// then only until it quits — unless it keeps a *security-scoped bookmark*,
/// which is what this stores: bytes that re-grant access, not a path. A path
/// alone would be a string the app is not allowed to open.
///
/// There is no fixed default and there can't be one. The app's own iCloud
/// container would need a paid developer membership, and `~/Library/Mobile
/// Documents` is outside the sandbox until it's chosen — so the folder is
/// chosen once, and the panel opens in iCloud Drive because that is where a
/// backup belongs: already syncing, already off this machine.
@MainActor
enum BackupFolder {
    private static let bookmarkKey = "backupFolderBookmark"
    private static let lastBackupKey = "lastBackupAt"

    /// The chosen folder, or `nil` if none has been picked or the bookmark no
    /// longer resolves — the folder was deleted, or moved somewhere the app
    /// wasn't granted.
    static var current: URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }

        var isStale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        else {
            return nil
        }

        // The folder moved. The resolved URL still works; the stored bytes
        // won't next time, so they're rewritten now.
        if isStale {
            remember(url)
        }

        return url
    }

    static var lastBackup: Date? {
        UserDefaults.standard.object(forKey: lastBackupKey) as? Date
    }

    static func recordBackup(at date: Date = .now) {
        UserDefaults.standard.set(date, forKey: lastBackupKey)
    }

    /// Asks for a folder. `nil` if the panel was cancelled.
    static func choose() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose where Scade should write its backups."
        panel.directoryURL = iCloudDrive

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        remember(url)
        return url
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    /// Runs `work` with the sandbox's permission to write inside `url`.
    ///
    /// Every access has to be bracketed like this — the grant is not
    /// permanent, it is opened and closed around the work.
    static func withAccess<T>(to url: URL, _ work: (URL) throws -> T) rethrows -> T {
        let opened = url.startAccessingSecurityScopedResource()
        defer {
            if opened {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try work(url)
    }

    private static func remember(_ url: URL) {
        guard
            let data = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        else {
            return
        }

        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    /// Built from the real home directory, not `FileManager`'s — inside a
    /// sandbox that one answers with the container. Only ever handed to the
    /// panel, which runs outside the sandbox and can open it.
    private static var iCloudDrive: URL? {
        guard let entry = getpwuid(getuid()), let home = entry.pointee.pw_dir else { return nil }

        return URL(fileURLWithPath: String(cString: home))
            .appending(path: "Library/Mobile Documents/com~apple~CloudDocs", directoryHint: .isDirectory)
    }
}
#endif
