import ScadeKit
import SwiftUI

/// The three repositories, handed to the view layer as one value.
///
/// Holds no rows — it is a handle for making queries, not a cache. Screens
/// mostly don't call these directly any more: they observe a query through
/// `database.observe…` and are handed a fresh result whenever the rows behind
/// it change. What's left here backs the writes, the forms, and Settings.
public struct Repositories: Sendable {
    public let educations: EducationRepository
    public let subjects: SubjectRepository
    public let grades: GradeRepository

    /// Kept for the one job that isn't a repository's: writing an export
    /// snapshot of the whole file (§4).
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
        educations = EducationRepository(database: database)
        subjects = SubjectRepository(database: database)
        grades = GradeRepository(database: database)
    }
}

extension Repositories {
    /// Backs previews and the environment default.
    ///
    /// The real app injects a file-backed store at the root; this exists so a
    /// preview never has to reach for one.
    public static let inMemory: Repositories = {
        guard let database = try? AppDatabase.inMemory() else {
            fatalError("Could not open an in-memory database for previews")
        }
        return Repositories(database: database)
    }()
}

extension EnvironmentValues {
    /// Replaced at the root with a file-backed store. The default is
    /// in-memory so previews work without ceremony.
    @Entry public var repositories = Repositories.inMemory
}
