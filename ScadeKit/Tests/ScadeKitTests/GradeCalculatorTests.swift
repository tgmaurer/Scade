import Foundation
import Testing

@testable import ScadeKit

@Suite("GradeCalculator — subject average (§3.1)")
struct SubjectAverageTests {

    /// The old app returned `0` here and relied on 0 being outside the 1–6
    /// range. `nil` says the same thing without the convention.
    @Test("A subject with no grades has no average, rather than an average of zero")
    func noGradesGivesNil() {
        let average = GradeCalculator.subjectAverage(of: [])

        #expect(average == nil)
        #expect(average != 0)
    }

    @Test("A single grade is its own average, whatever its weight")
    func singleGrade() throws {
        try expectApproximately(
            GradeCalculator.subjectAverage(of: [Fixture.grade(subjectId: 1, value: 5.25)]),
            5.25
        )
        try expectApproximately(
            GradeCalculator.subjectAverage(
                of: [Fixture.grade(subjectId: 1, value: 5.25, weight: 0.375)]
            ),
            5.25
        )
    }

    @Test("Equal weights give the plain mean")
    func equalWeights() throws {
        let grades = [
            Fixture.grade(subjectId: 1, value: 4.0),
            Fixture.grade(subjectId: 1, value: 5.0),
            Fixture.grade(subjectId: 1, value: 6.0),
        ]

        try expectApproximately(GradeCalculator.subjectAverage(of: grades), 5.0)
    }

    @Test("Unequal weights pull the average toward the heavier grade")
    func unequalWeights() throws {
        // (5.0 × 1.0 + 6.0 × 0.5) / 1.5 = 8.0 / 1.5
        let grades = [
            Fixture.grade(subjectId: 1, value: 5.0, weight: 1.0),
            Fixture.grade(subjectId: 1, value: 6.0, weight: 0.5),
        ]

        try expectApproximately(GradeCalculator.subjectAverage(of: grades), 8.0 / 1.5)
    }

    @Test("Handles the fractional weights the quick-picks produce")
    func fractionalWeights() throws {
        // Quick-picks from §4: 62.5% and 37.5%.
        // (6.0 × 0.625 + 4.0 × 0.375) / 1.0 = 5.25
        let grades = [
            Fixture.grade(subjectId: 1, value: 6.0, weight: 0.625),
            Fixture.grade(subjectId: 1, value: 4.0, weight: 0.375),
        ]

        try expectApproximately(GradeCalculator.subjectAverage(of: grades), 5.25)
    }

    @Test("Does not depend on the order the grades arrive in")
    func orderIndependent() throws {
        let grades = [
            Fixture.grade(subjectId: 1, value: 6.0, weight: 2.0),
            Fixture.grade(subjectId: 1, value: 4.0, weight: 0.5),
            Fixture.grade(subjectId: 1, value: 5.5, weight: 1.25),
        ]

        let forward = GradeCalculator.subjectAverage(of: grades)
        let reversed = GradeCalculator.subjectAverage(of: grades.reversed())

        try expectApproximately(forward, try #require(reversed))
    }

    @Test("Reads the grades off a fetched subject the same way")
    func acceptsSubjectGrades() throws {
        let subject = Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [4.0, 6.0])

        try expectApproximately(GradeCalculator.subjectAverage(of: subject), 5.0)
    }
}

@Suite("GradeCalculator — education rollup (§3.2)")
struct EducationAverageTests {

    @Test("An education with no subjects has no average")
    func noSubjectsGivesNil() {
        #expect(GradeCalculator.educationAverage(of: []) == nil)
    }

    @Test("An education whose subjects are all ungraded has no average")
    func noGradedSubjectsGivesNil() {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: []),
            Fixture.subjectGrades(subjectWeight: 2.0, gradeValues: []),
        ]

        let average = GradeCalculator.educationAverage(of: subjects)

        #expect(average == nil)
        #expect(average != 0)
    }

    /// Preserved from the old app: a subject you haven't been marked in yet
    /// shouldn't drag the average toward zero.
    @Test("Ungraded subjects are left out rather than counted as zero")
    func ungradedSubjectsAreExcluded() throws {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [5.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: []),
        ]

        try expectApproximately(GradeCalculator.educationAverage(of: subjects), 5.0)
    }

    /// The change this column was added for. The old app took a plain mean of
    /// subject averages; a 3×-weighted subject now counts three times.
    @Test("Subjects are weighted, not averaged evenly")
    func weightsSubjectsRatherThanAveragingThem() throws {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 3.0, gradeValues: [6.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [4.0]),
        ]

        let average = GradeCalculator.educationAverage(of: subjects)

        // (6.0 × 3 + 4.0 × 1) / 4 = 5.5
        try expectApproximately(average, 5.5)

        // The old app's unweighted mean would have said 5.0.
        #expect(average != 5.0)
    }

    /// The subject's weight scales its *average*, not each of its grades — a
    /// subject with two grades doesn't get twice the say.
    @Test("Subject weight applies to the subject average, not to each grade")
    func weightAppliesToTheAverageNotEachGrade() throws {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 3.0, gradeValues: [6.0, 6.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [4.0]),
        ]

        let average = GradeCalculator.educationAverage(of: subjects)

        // (6.0 × 3 + 4.0 × 1) / 4 = 5.5
        try expectApproximately(average, 5.5)

        // Weighting each grade instead would have given 40 / 7 ≈ 5.714.
        #expect(abs(try #require(average) - (40.0 / 7.0)) > 0.1)
    }

    @Test("Equal subject weights reduce to the mean of the subject averages")
    func equalWeightsMatchThePlainMean() throws {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [6.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [4.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [5.0]),
        ]

        try expectApproximately(GradeCalculator.educationAverage(of: subjects), 5.0)
    }

    @Test("Rolls up weighted subject averages, not raw grade values")
    func rollsUpSubjectAverages() throws {
        let subjects = [
            // (5.0 × 1 + 6.0 × 0.5) / 1.5 = 5.3333…, weighted 2
            Fixture.subjectGrades(
                subjectWeight: 2.0, gradeValues: [5.0, 6.0], gradeWeights: [1.0, 0.5]
            ),
            // 4.5, weighted 1
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [4.0, 5.0]),
        ]

        let first = 8.0 / 1.5
        let expected = (first * 2.0 + 4.5 * 1.0) / 3.0

        try expectApproximately(GradeCalculator.educationAverage(of: subjects), expected)
    }

    @Test("Does not depend on the order the subjects arrive in")
    func orderIndependent() throws {
        let subjects = [
            Fixture.subjectGrades(subjectWeight: 2.5, gradeValues: [5.5, 6.0]),
            Fixture.subjectGrades(subjectWeight: 0.5, gradeValues: [4.0]),
            Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: []),
        ]

        let forward = GradeCalculator.educationAverage(of: subjects)
        let reversed = GradeCalculator.educationAverage(of: subjects.reversed())

        try expectApproximately(forward, try #require(reversed))
    }

    /// `CHECK (weight > 0)` makes this unreachable through the database, but
    /// the calculator returns `nil` rather than dividing by zero if a bad row
    /// ever reaches it another way.
    @Test("Returns nil instead of dividing by a zero total weight")
    func guardsAgainstZeroTotalWeight() {
        let subjects = [Fixture.subjectGrades(subjectWeight: 0.0, gradeValues: [5.0])]

        #expect(GradeCalculator.educationAverage(of: subjects) == nil)
    }
}

@Suite("GradingScale")
struct GradingScaleTests {

    @Test("Accepts both ends of the scale and nothing outside it")
    func rangeBounds() {
        #expect(GradingScale.contains(1.0))
        #expect(GradingScale.contains(6.0))
        #expect(GradingScale.contains(0.99) == false)
        #expect(GradingScale.contains(6.01) == false)
        #expect(GradingScale.contains(0.0) == false)
    }

    @Test("Fails below 4, passes from 4 up")
    func passingThreshold() {
        #expect(GradingScale.isFailing(3.99))
        #expect(GradingScale.isFailing(1.0))
        #expect(GradingScale.isFailing(4.0) == false)
        #expect(GradingScale.isFailing(6.0) == false)
    }

    @Test("A grade reports its own failing state")
    func gradeReportsFailingState() {
        #expect(Fixture.grade(subjectId: 1, value: 3.5).isFailing)
        #expect(Fixture.grade(subjectId: 1, value: 4.0).isFailing == false)
    }
}
