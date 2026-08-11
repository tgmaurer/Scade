import Foundation

extension UserDefaults {
    /// Where the app keeps its preferences.
    ///
    /// `.standard`, unless UI tests asked for a throwaway store — for the same
    /// reason they get a throwaway database. Automation would otherwise
    /// inherit the last run's remembered selections, and record ids restart at
    /// 1 on every run against an in-memory database, so a stale id wouldn't
    /// just be ignored: it could match a *different* record.
    ///
    /// Emptied at launch rather than merely separated, so one automated run
    /// can't reach the next either.
    static let scade: UserDefaults = {
        // Matches the argument in `ScadeApp`; see the constant there.
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing") else {
            return .standard
        }

        let suite = "scade.ui-testing"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }()
}
