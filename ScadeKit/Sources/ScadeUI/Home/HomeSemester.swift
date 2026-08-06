import ScadeKit
import SwiftUI

/// One semester's worth of the dashboard.
///
/// Semester is the unit a student thinks in, so it's the unit Home groups by
/// (SPEC-POLISH §2.3). The old app sorted a flat table by semester and welded
/// the number into each row's name (`English - 4`); this carries the same
/// information as structure instead.
struct HomeSemester: Identifiable, Hashable, Sendable {
    let semester: Int
    let subjects: [HomeSubject]

    var id: Int { semester }

    /// "Semester 3" — the section heading.
    var title: LocalizedStringKey {
        "Semester \(semester.formatted(.number.grouping(.never)))"
    }

    /// Groups subjects by semester, **highest first**.
    ///
    /// Descending because SPEC §3.6 makes `semester desc` the canonical order
    /// for subjects everywhere, and because the semester a student is in now
    /// is the one they opened the app to look at. Sorted rather than left in
    /// fetch order: a dashboard that reorders itself between loads is worse
    /// than one that's merely plain.
    static func grouping(_ subjects: [HomeSubject]) -> [HomeSemester] {
        Dictionary(grouping: subjects, by: \.subject.semester)
            .map { HomeSemester(semester: $0.key, subjects: $0.value) }
            .sorted { $0.semester > $1.semester }
    }
}
