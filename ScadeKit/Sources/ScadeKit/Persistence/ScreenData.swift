import Foundation
import GRDB

// What each screen reads, as one value fetched in one transaction.
//
// A screen that needs four queries used to make four separate reads, which
// could each see a different state of the database. Bundling them means the
// counts, the rows and the filter options a screen shows are always describing
// the same moment — and it gives `AppDatabase.observe` a single `Equatable`
// value to compare, so a write that changes nothing the screen shows doesn't
// republish it.
//
// These live here rather than beside their screens because the queries do; the
// view layer never names a GRDB type.

/// The dashboard: every education, and the full tree of the selected one.
public struct HomeData: Sendable, Equatable {
    public let educations: [Education]
    public let summary: EducationSummary?

    public init(educations: [Education], summary: EducationSummary?) {
        self.educations = educations
        self.summary = summary
    }
}

/// The educations list, with the values its institution filter offers.
public struct EducationListData: Sendable, Equatable {
    public let summaries: [EducationSummary]
    public let institutions: [String]

    public init(summaries: [EducationSummary], institutions: [String]) {
        self.summaries = summaries
        self.institutions = institutions
    }
}

/// The subjects list. The two flags drive the empty state, which has to say
/// *why* it's empty — no educations at all, or none still in progress (§4).
public struct SubjectListData: Sendable, Equatable {
    public let summaries: [SubjectSummary]
    public let institutions: [String]
    public let hasInProgressEducation: Bool
    public let hasAnyEducation: Bool

    public init(
        summaries: [SubjectSummary],
        institutions: [String],
        hasInProgressEducation: Bool,
        hasAnyEducation: Bool
    ) {
        self.summaries = summaries
        self.institutions = institutions
        self.hasInProgressEducation = hasInProgressEducation
        self.hasAnyEducation = hasAnyEducation
    }
}

/// The grades list, plus the subjects its filter offers.
public struct GradeListData: Sendable, Equatable {
    public let items: [GradeListItem]
    public let subjects: [Subject]

    public init(items: [GradeListItem], subjects: [Subject]) {
        self.items = items
        self.subjects = subjects
    }
}

// MARK: - Observations

extension AppDatabase {
    public func observeHome(educationId: Int64?) -> AsyncThrowingStream<HomeData, any Error> {
        observe { db in
            HomeData(
                educations: try EducationRepository.fetchAll(db),
                summary: try educationId.flatMap {
                    try EducationRepository.fetchSummary(id: $0, in: db)
                }
            )
        }
    }

    public func observeEducationList() -> AsyncThrowingStream<EducationListData, any Error> {
        observe { db in
            EducationListData(
                summaries: try EducationRepository.fetchAllSummaries(db),
                institutions: try EducationRepository.fetchDistinctInstitutions(db)
            )
        }
    }

    public func observeSubjectList() -> AsyncThrowingStream<SubjectListData, any Error> {
        observe { db in
            SubjectListData(
                summaries: try SubjectRepository.fetchAllSummaries(db),
                institutions: try EducationRepository.fetchDistinctInstitutions(db),
                hasInProgressEducation: try EducationRepository.fetchInProgress(db).isEmpty == false,
                hasAnyEducation: try EducationRepository.fetchCount(db) > 0
            )
        }
    }

    public func observeGradeList() -> AsyncThrowingStream<GradeListData, any Error> {
        observe { db in
            GradeListData(
                items: try GradeRepository.fetchAllListItems(db),
                subjects: try SubjectRepository.fetchAll(db)
            )
        }
    }

    // The detail screens read one thing each, so they need no wrapper. They
    // publish `nil` when the record is deleted, which is how a detail screen
    // left open on a deleted record finds out.

    public func observeEducation(id: Int64) -> AsyncThrowingStream<EducationSummary?, any Error> {
        observe { try EducationRepository.fetchSummary(id: id, in: $0) }
    }

    public func observeSubject(id: Int64) -> AsyncThrowingStream<SubjectSummary?, any Error> {
        observe { try SubjectRepository.fetchSummary(id: id, in: $0) }
    }

    public func observeGrade(id: Int64) -> AsyncThrowingStream<GradeListItem?, any Error> {
        observe { try GradeRepository.fetchListItem(id: id, in: $0) }
    }
}
