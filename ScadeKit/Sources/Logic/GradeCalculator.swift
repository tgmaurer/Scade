import Foundation

/// Every average in Scade, computed in one place.
///
/// The old app had the same formula written out twice — once in `SubjectUtils`
/// and once, unused and already drifting, in `EducationUtils` (SPEC §3.2).
/// Both averages here funnel through the same `weightedMean`, so there is one
/// implementation to test and nowhere for a second copy to diverge.
///
/// "No data" is `nil`, not `0`. The old app returned `0` and leaned on it
/// being outside the 1–6 range, which meant every call site had to remember
/// the convention. An optional says the same thing and makes the compiler
/// bring it up.
public enum GradeCalculator {

    /// A subject's weighted average (§3.1), or `nil` if it has no grades yet.
    public static func subjectAverage(of grades: [Grade]) -> Double? {
        weightedMean(grades.map { (value: $0.value, weight: $0.weight) })
    }

    /// A subject's weighted average, taken from a fetched subject/grade pair.
    public static func subjectAverage(of subjectGrades: SubjectGrades) -> Double? {
        subjectAverage(of: subjectGrades.grades)
    }

    /// An education's weighted average (§3.2), or `nil` if none of its
    /// subjects has a grade yet.
    ///
    /// Subjects without grades are left out entirely rather than counted as
    /// zero — a subject you haven't been marked in yet shouldn't drag the
    /// average down. This differs from the old app in one way: subjects are
    /// now weighted by `Subject.weight` instead of contributing equally,
    /// which is the whole reason that column exists.
    ///
    /// - Parameter subjects: subjects with their grades already fetched.
    public static func educationAverage(of subjects: [SubjectGrades]) -> Double? {
        let qualifying = subjects.compactMap { entry -> (value: Double, weight: Double)? in
            guard let average = subjectAverage(of: entry.grades) else { return nil }
            return (value: average, weight: entry.subject.weight)
        }

        return weightedMean(qualifying)
    }

    /// The shared kernel: `Σ(value × weight) / Σweight`.
    ///
    /// Returns `nil` for an empty input, and also for a non-positive total
    /// weight. The database enforces `weight > 0`, so that second case should
    /// be unreachable — but returning `nil` beats dividing by zero if a bad
    /// row ever gets in some other way.
    private static func weightedMean(_ entries: [(value: Double, weight: Double)]) -> Double? {
        guard entries.isEmpty == false else { return nil }

        let totalWeight = entries.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }

        let weightedSum = entries.reduce(0) { $0 + ($1.value * $1.weight) }
        return weightedSum / totalWeight
    }
}
