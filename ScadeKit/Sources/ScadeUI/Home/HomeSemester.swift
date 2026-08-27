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

    /// Groups subjects by semester, **highest first**, keeping the order
    /// they arrived in within each group.
    ///
    /// Descending because SPEC §3.6 makes `semester desc` canonical, and
    /// because the semester a student is in now is the one they opened the app
    /// to look at.
    ///
    /// Built by hand rather than with `Dictionary(grouping:)`, which returns
    /// its groups in no defined order — that silently threw away the rest of
    /// §3.6's order (name ascending) that the query had already applied, so
    /// subjects within a semester came out arbitrary.
    static func grouping(_ subjects: [HomeSubject]) -> [HomeSemester] {
        var order: [Int] = []
        var groups: [Int: [HomeSubject]] = [:]

        for subject in subjects {
            let semester = subject.subject.semester
            if groups[semester] == nil {
                order.append(semester)
            }
            groups[semester, default: []].append(subject)
        }

        return
            order
            .map { HomeSemester(semester: $0, subjects: groups[$0] ?? []) }
            .sorted { $0.semester > $1.semester }
    }
}
