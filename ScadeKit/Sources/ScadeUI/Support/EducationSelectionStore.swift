import Foundation

/// Remembers which education the dashboard was last showing.
///
/// **Why this exists at all.** `HomeScreen` holds its model in `@State`, and
/// the screen doesn't outlive a section switch — macOS replaces the whole
/// detail column, so coming back to Home builds a new model with no selection
/// and the dashboard fell back to the newest education. The selection has to
/// live somewhere longer-lived than the screen.
///
/// **Why it persists rather than just outliving the screen.** Once it's out of
/// the view, writing it down costs nothing more, and "newest created" is a bad
/// guess for this app: educations run in parallel and last for years
/// (SPEC-POLISH §0.2), so the newest is simply whichever was added last, not
/// the one being worked in. Relaunching into the one you were last using is
/// almost always right, and when it isn't, switching is one click.
///
/// A remembered education that has since been deleted is not an error case to
/// guard against here — `HomeModel` already resolves a selection it can't find
/// to the newest, which is also what a first launch gets.
struct EducationSelectionStore: Sendable {
    static let shared = EducationSelectionStore(defaults: .scade)

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private static let key = "home.selectedEducationId"

    func remembered() -> Int64? {
        // `integer(forKey:)` reads a missing key as 0, which is not a valid
        // row id, so it doubles as "nothing remembered".
        let stored = defaults.integer(forKey: Self.key)
        return stored > 0 ? Int64(stored) : nil
    }

    func remember(_ id: Int64?) {
        guard let id else {
            defaults.removeObject(forKey: Self.key)
            return
        }

        defaults.set(Int(id), forKey: Self.key)
    }
}
