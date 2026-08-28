import Foundation
import Testing

@testable import ScadeKit

/// One education of the shape a real one has, with the arithmetic written
/// out longhand.
///
/// `GradeCalculatorTests` takes the rules apart one at a time, which is the
/// right way to say what each one means and the wrong way to catch them
/// interacting. Every case there is two or three subjects with round
/// numbers; nothing exercises a fractional subject weight, a multi-grade
/// subject, an excluded subject and a subject that counts for nothing all at
/// once — which is what an education in use actually looks like, and the
/// only arrangement where a rule applied at the wrong level still produces a
/// plausible number.
@Suite("Averages — a whole education worked longhand")
struct WholeEducationAverageTests {

    /// | subject | weight | grades          | its average          |
    /// |---------|--------|-----------------|----------------------|
    /// | Modul   | 1.0    | 5.5@100%, 4@50% | (5.5 + 2.0) / 1.5 = 5.0 |
    /// | Mathe   | 1.5    | 4.0@100%        | 4.0                  |
    /// | English | 0.7    | 3.0, 6.0        | 4.5                  |
    /// | Sport   | 0.0    | 1.0             | 1.0, and counts for nothing |
    /// | Physik  | 1.0    | none            | excluded entirely    |
    ///
    /// weightedSum = 5.0×1.0 + 4.0×1.5 + 4.5×0.7 + 1.0×0.0 = 14.15
    /// totalWeight = 1.0 + 1.5 + 0.7 + 0.0                 =  3.2
    /// average     = 14.15 / 3.2                           =  4.421875
    private let education = [
        Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: [5.5, 4.0], gradeWeights: [1.0, 0.5]),
        Fixture.subjectGrades(subjectWeight: 1.5, gradeValues: [4.0]),
        Fixture.subjectGrades(subjectWeight: 0.7, gradeValues: [3.0, 6.0]),
        Fixture.subjectGrades(subjectWeight: 0.0, gradeValues: [1.0]),
        Fixture.subjectGrades(subjectWeight: 1.0, gradeValues: []),
    ]

    @Test("Each subject averages its own grades")
    func subjectAverages() throws {
        try expectApproximately(GradeCalculator.subjectAverage(of: education[0]), 5.0)
        try expectApproximately(GradeCalculator.subjectAverage(of: education[1]), 4.0)
        try expectApproximately(GradeCalculator.subjectAverage(of: education[2]), 4.5)
        try expectApproximately(GradeCalculator.subjectAverage(of: education[3]), 1.0)
        #expect(GradeCalculator.subjectAverage(of: education[4]) == nil)
    }

    @Test("The education rolls them up by subject weight")
    func educationAverage() throws {
        try expectApproximately(GradeCalculator.educationAverage(of: education), 4.421875)
    }

    /// The failure this is really watching for: rolling up raw grade values
    /// instead of subject averages. It gives a number in range, close enough
    /// to look right on screen, and only a worked example catches it.
    @Test("Which is not the same as averaging every grade in the education")
    func isNotAFlatAverageOfEveryGrade() throws {
        let everyGrade = education.flatMap(\.grades)
        let flat = GradeCalculator.subjectAverage(of: everyGrade)

        let rollup = try #require(GradeCalculator.educationAverage(of: education))
        let flatValue = try #require(flat)

        #expect(abs(rollup - flatValue) > 0.1)
    }
}

/// What has to hold for *any* input, rather than for the cases someone
/// thought to write down.
///
/// A worked example pins one arrangement; these pin the shape of the
/// formula, and they fail on the arithmetic slips a fixture can sit on top
/// of — a sum taken over the wrong collection, a weight applied twice, a
/// divisor that isn't the total weight.
@Suite("Averages — invariants")
struct AverageInvariantTests {

    private static let gradeSets: [[Double]] = [
        [5.0],
        [4.0, 6.0],
        [1.0, 3.25, 5.5, 6.0],
        [4.75, 4.75, 4.75],
    ]

    /// Weights are relative. Halving or doubling every one of them says the
    /// same thing about how the grades compare, so the average cannot move.
    @Test("Scaling every grade weight leaves the subject average alone", arguments: [0.5, 2.0, 7.3])
    func gradeWeightsAreRelative(factor: Double) throws {
        for values in Self.gradeSets {
            let weights = values.indices.map { Double($0 + 1) / 4.0 }
            let plain = zip(values, weights).map {
                Fixture.grade(subjectId: 1, value: $0, weight: $1)
            }
            let scaled = zip(values, weights).map {
                Fixture.grade(subjectId: 1, value: $0, weight: $1 * factor)
            }

            let expected = try #require(GradeCalculator.subjectAverage(of: plain))
            try expectApproximately(GradeCalculator.subjectAverage(of: scaled), expected)
        }
    }

    @Test("Scaling every subject weight leaves the education average alone", arguments: [0.5, 2.0, 7.3])
    func subjectWeightsAreRelative(factor: Double) throws {
        let weights = [1.0, 0.25, 1.5]
        let plain = zip(weights, Self.gradeSets).map {
            Fixture.subjectGrades(subjectWeight: $0, gradeValues: $1)
        }
        let scaled = zip(weights, Self.gradeSets).map {
            Fixture.subjectGrades(subjectWeight: $0 * factor, gradeValues: $1)
        }

        let expected = try #require(GradeCalculator.educationAverage(of: plain))
        try expectApproximately(GradeCalculator.educationAverage(of: scaled), expected)
    }

    /// A weighted mean is a point between its inputs. Anything outside that
    /// range is not an average of them, whatever the formula did.
    @Test("A subject average lies between its lowest and highest grade")
    func subjectAverageStaysInRange() throws {
        for values in Self.gradeSets {
            let grades = values.enumerated().map { index, value in
                Fixture.grade(subjectId: 1, value: value, weight: Double(index + 1) / 3.0)
            }

            let average = try #require(GradeCalculator.subjectAverage(of: grades))

            #expect(average >= values.min()!)
            #expect(average <= values.max()!)
        }
    }

    @Test("An education average lies between its lowest and highest subject average")
    func educationAverageStaysInRange() throws {
        let subjects = Self.gradeSets.enumerated().map { index, values in
            Fixture.subjectGrades(subjectWeight: Double(index + 1) / 2.0, gradeValues: values)
        }
        let subjectAverages = subjects.compactMap { GradeCalculator.subjectAverage(of: $0) }

        let average = try #require(GradeCalculator.educationAverage(of: subjects))

        #expect(average >= subjectAverages.min()!)
        #expect(average <= subjectAverages.max()!)
    }

    /// Whatever its value. A 1.0 at 0% must not drag the average down and a
    /// 6.0 at 0% must not lift it.
    @Test("A grade at zero weight never moves the average", arguments: [1.0, 4.0, 6.0])
    func zeroWeightGradesAreInert(passenger: Double) throws {
        for values in Self.gradeSets {
            let grades = values.map { Fixture.grade(subjectId: 1, value: $0) }
            let expected = try #require(GradeCalculator.subjectAverage(of: grades))

            let withPassenger = grades + [
                Fixture.grade(subjectId: 1, value: passenger, weight: 0)
            ]

            try expectApproximately(GradeCalculator.subjectAverage(of: withPassenger), expected)
        }
    }

    /// Recording the same result twice says nothing new about the subject.
    @Test("Repeating a grade doesn't move the average")
    func duplicatesAreInert() throws {
        for values in Self.gradeSets {
            let grades = values.map { Fixture.grade(subjectId: 1, value: $0, weight: 0.75) }
            let expected = try #require(GradeCalculator.subjectAverage(of: grades))

            try expectApproximately(GradeCalculator.subjectAverage(of: grades + grades), expected)
        }
    }
}
