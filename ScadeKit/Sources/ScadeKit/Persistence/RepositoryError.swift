import Foundation
import GRDB

/// Failures a repository raises in its own terms, rather than leaking raw
/// SQLite result codes to callers.
public enum RepositoryError: Error, Equatable, Sendable {
    /// An update or delete was handed a record that has never been inserted.
    case missingIdentifier

    /// The row the caller wanted to change is no longer there.
    case notFound

    /// Another subject in this education already uses this name and semester.
    ///
    /// Raised by the `idx_subjects_unique` index (SPEC §2). Validation cannot
    /// pre-empt this reliably — checking then inserting is exactly the race
    /// the index exists to close — so it surfaces as an error to show on the
    /// name field.
    case duplicateSubject
}

extension DatabaseError {
    /// True when this error came from a `UNIQUE` index violation.
    var isUniqueConstraintViolation: Bool {
        extendedResultCode == .SQLITE_CONSTRAINT_UNIQUE
            || extendedResultCode == .SQLITE_CONSTRAINT_PRIMARYKEY
    }
}
