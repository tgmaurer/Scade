import Foundation

/// Something a search field can match against.
///
/// SPEC §3.5 makes search a plain substring match with no embedded syntax:
/// name and description, plus the parent entity's name for subjects and
/// grades. Conformances below are the single definition of "which fields are
/// searched" for each list screen.
public protocol Searchable {
    /// The text this item can be found by. `nil` entries are skipped.
    var searchableFields: [String?] { get }
}

extension Searchable {
    /// Whether this item matches `query`.
    ///
    /// Matching happens in Swift, not in SQL. `LIKE` with SQLite's `NOCASE`
    /// collation is ASCII-only, so the old app couldn't match `ü`, `ö` or `ä`
    /// case-insensitively. `localizedStandardContains` is Unicode-aware and
    /// also ignores diacritics, so "padagogik" finds "Pädagogik" — the
    /// behaviour a search field is expected to have.
    public func matches(searchQuery query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return true }

        return searchableFields.contains { field in
            guard let field else { return false }
            return field.localizedStandardContains(trimmed)
        }
    }
}

extension Sequence where Element: Searchable {
    /// The items matching `query`, in their existing order.
    ///
    /// Order is preserved rather than re-derived, so the canonical sort the
    /// repository applied (§3.6) survives the search — "unaffected by search",
    /// as the spec puts it.
    public func matching(searchQuery query: String) -> [Element] {
        filter { $0.matches(searchQuery: query) }
    }
}

extension Education: Searchable {
    public var searchableFields: [String?] {
        [name, description, institution]
    }
}

extension Subject: Searchable {
    public var searchableFields: [String?] {
        [name, description]
    }
}

extension SubjectListItem: Searchable {
    public var searchableFields: [String?] {
        [subject.name, subject.description, education.name]
    }
}

extension GradeListItem: Searchable {
    public var searchableFields: [String?] {
        [grade.description, subject.name, education.name]
    }
}
