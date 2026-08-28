import Foundation
import Testing

@testable import ScadeKit

@Suite("EducationValidator (§3.4)")
struct EducationValidatorTests {

    @Test("Accepts a well-formed education")
    func acceptsValidEducation() {
        #expect(EducationValidator.validate(Fixture.education()).isEmpty)
    }

    @Test("Requires a name", arguments: ["", " ", "\n", "   \t  "])
    func requiresName(name: String) {
        #expect(EducationValidator.validate(Fixture.education(name: name)) == [.nameRequired])
    }

    @Test("Caps the name at 255 characters")
    func capsNameLength() {
        let maximum = ValidationLimits.maximumNameLength

        #expect(
            EducationValidator.validate(
                Fixture.education(name: String(repeating: "a", count: maximum))
            ).isEmpty
        )
        #expect(
            EducationValidator.validate(
                Fixture.education(name: String(repeating: "a", count: maximum + 1))
            ) == [.nameTooLong(maximum: maximum)]
        )
    }

    @Test("Ignores surrounding whitespace when measuring the name")
    func trimsBeforeMeasuringName() {
        let name = "  " + String(repeating: "a", count: ValidationLimits.maximumNameLength) + "  "

        #expect(EducationValidator.validate(Fixture.education(name: name)).isEmpty)
    }

    @Test("Caps the description at 2500 characters, and allows none at all")
    func capsDescriptionLength() {
        let maximum = ValidationLimits.maximumDescriptionLength

        #expect(EducationValidator.validate(Fixture.education(description: nil)).isEmpty)
        #expect(
            EducationValidator.validate(
                Fixture.education(description: String(repeating: "a", count: maximum))
            ).isEmpty
        )
        #expect(
            EducationValidator.validate(
                Fixture.education(description: String(repeating: "a", count: maximum + 1))
            ) == [.descriptionTooLong(maximum: maximum)]
        )
    }

    @Test("Requires at least one semester", arguments: [0, -1, -10])
    func requiresAtLeastOneSemester(semesters: Int) {
        #expect(
            EducationValidator.validate(Fixture.education(semesters: semesters))
                == [.semestersOutOfRange(minimum: 1)]
        )
    }

    @Test("Accepts a single-semester education")
    func acceptsOneSemester() {
        #expect(EducationValidator.validate(Fixture.education(semesters: 1)).isEmpty)
    }

    @Test("Rejects an end date before the start date")
    func rejectsInvertedRange() {
        let education = Fixture.education(
            startDate: .iso("2026-09-01"),
            endDate: .iso("2026-08-31")
        )

        #expect(EducationValidator.validate(education) == [.endDateBeforeStartDate])
    }

    @Test("Accepts an education that starts and ends on the same day")
    func acceptsSingleDayRange() {
        let education = Fixture.education(
            startDate: .iso("2026-09-01"),
            endDate: .iso("2026-09-01")
        )

        #expect(EducationValidator.validate(education).isEmpty)
    }

    /// Forms show every problem at once rather than one save at a time.
    @Test("Reports every broken rule together")
    func reportsAllErrors() {
        let education = Fixture.education(
            name: "",
            semesters: 0,
            startDate: .iso("2026-09-01"),
            endDate: .iso("2026-08-31")
        )

        let errors = EducationValidator.validate(education)

        #expect(errors.count == 3)
        #expect(errors.contains(.nameRequired))
        #expect(errors.contains(.semestersOutOfRange(minimum: 1)))
        #expect(errors.contains(.endDateBeforeStartDate))
    }

    @Test("Points each error at the field it belongs to")
    func mapsErrorsToFields() {
        #expect(ValidationError.nameRequired.field == .name)
        #expect(ValidationError.nameTooLong(maximum: 255).field == .name)
        #expect(ValidationError.descriptionTooLong(maximum: 2500).field == .description)
        #expect(ValidationError.semestersOutOfRange(minimum: 1).field == .semesters)
        #expect(ValidationError.endDateBeforeStartDate.field == .endDate)
        #expect(ValidationError.semesterOutOfRange(minimum: 1, maximum: 6).field == .semester)
        #expect(ValidationError.weightNegative.field == .weight)
        #expect(ValidationError.valueOutOfRange(minimum: 1, maximum: 6).field == .value)
        #expect(
            ValidationError.dateOutsideEducationRange(
                start: .iso("2024-09-01"), end: .iso("2027-08-31")
            ).field == .date
        )
    }
}

@Suite("SubjectValidator (§3.4)")
struct SubjectValidatorTests {
    let education = Fixture.education(semesters: 6)

    @Test("Accepts a well-formed subject")
    func acceptsValidSubject() {
        #expect(SubjectValidator.validate(Fixture.subject(educationId: 1), in: education).isEmpty)
    }

    @Test("Requires a name")
    func requiresName() {
        let subject = Fixture.subject(educationId: 1, name: "   ")

        #expect(SubjectValidator.validate(subject, in: education) == [.nameRequired])
    }

    @Test("Caps the name and description at the shared limits")
    func capsTextLengths() {
        let longName = Fixture.subject(
            educationId: 1,
            name: String(repeating: "a", count: ValidationLimits.maximumNameLength + 1)
        )
        let longDescription = Fixture.subject(
            educationId: 1,
            description: String(repeating: "a", count: ValidationLimits.maximumDescriptionLength + 1)
        )

        #expect(
            SubjectValidator.validate(longName, in: education)
                == [.nameTooLong(maximum: ValidationLimits.maximumNameLength)]
        )
        #expect(
            SubjectValidator.validate(longDescription, in: education)
                == [.descriptionTooLong(maximum: ValidationLimits.maximumDescriptionLength)]
        )
    }

    @Test("Accepts every semester the education actually has", arguments: 1...6)
    func acceptsSemestersWithinEducation(semester: Int) {
        let subject = Fixture.subject(educationId: 1, semester: semester)

        #expect(SubjectValidator.validate(subject, in: education).isEmpty)
    }

    /// The old app clamped this to the education's maximum and raised a toast.
    /// Scade reports it instead, and leaves the user's input alone.
    @Test("Rejects a semester past the education's last one, instead of clamping it")
    func rejectsSemesterBeyondEducation() {
        let subject = Fixture.subject(educationId: 1, semester: 7)

        let errors = SubjectValidator.validate(subject, in: education)

        #expect(errors == [.semesterOutOfRange(minimum: 1, maximum: 6)])
        // The value the user typed is still the value they typed.
        #expect(subject.semester == 7)
    }

    @Test("Rejects a semester below the first one", arguments: [0, -1])
    func rejectsSemesterBelowOne(semester: Int) {
        let subject = Fixture.subject(educationId: 1, semester: semester)

        #expect(
            SubjectValidator.validate(subject, in: education)
                == [.semesterOutOfRange(minimum: 1, maximum: 6)]
        )
    }

    @Test("Rejects a negative weight", arguments: [-1.0, -0.5])
    func rejectsNegativeWeight(weight: Double) {
        let subject = Fixture.subject(educationId: 1, weight: weight)

        #expect(SubjectValidator.validate(subject, in: education) == [.weightNegative])
    }

    /// A subject that doesn't count towards its education is a real thing to
    /// record, not a mistake to catch.
    @Test("Accepts a weight of zero")
    func acceptsZeroWeight() {
        let subject = Fixture.subject(educationId: 1, weight: 0)

        #expect(SubjectValidator.validate(subject, in: education).isEmpty)
    }

    @Test("Rejects a weight that isn't a number")
    func rejectsNonFiniteWeight() {
        #expect(
            SubjectValidator.validate(Fixture.subject(educationId: 1, weight: .nan), in: education)
                == [.weightNegative]
        )
        #expect(
            SubjectValidator.validate(
                Fixture.subject(educationId: 1, weight: .infinity), in: education
            ) == [.weightNegative]
        )
    }

    @Test("Accepts the fractional weights the quick-picks produce", arguments: [0.0, 0.125, 0.5, 1.0, 1.25, 3.0])
    func acceptsFractionalWeights(weight: Double) {
        let subject = Fixture.subject(educationId: 1, weight: weight)

        #expect(SubjectValidator.validate(subject, in: education).isEmpty)
    }
}

@Suite("GradeValidator (§3.4)")
struct GradeValidatorTests {
    let education = Fixture.education(
        startDate: .iso("2024-09-01"),
        endDate: .iso("2027-08-31")
    )

    @Test("Accepts a well-formed grade")
    func acceptsValidGrade() {
        #expect(GradeValidator.validate(Fixture.grade(subjectId: 1), in: education).isEmpty)
    }

    /// The headline case from §3.4: the old app's form carried a `Min=0`
    /// bound that never matched its own `[Range(1, 6)]` rule. Zero is not a
    /// grade.
    @Test("Rejects zero, which the old app's form would have allowed")
    func rejectsZero() {
        let grade = Fixture.grade(subjectId: 1, value: 0.0)

        #expect(
            GradeValidator.validate(grade, in: education)
                == [.valueOutOfRange(minimum: 1.0, maximum: 6.0)]
        )
    }

    @Test("Rejects values outside the 1–6 scale", arguments: [0.0, 0.99, -1.0, 6.01, 7.0, 100.0])
    func rejectsOutOfScaleValues(value: Double) {
        let grade = Fixture.grade(subjectId: 1, value: value)

        #expect(
            GradeValidator.validate(grade, in: education)
                == [.valueOutOfRange(minimum: 1.0, maximum: 6.0)]
        )
    }

    @Test("Accepts both ends of the scale and everything between", arguments: [1.0, 3.5, 4.0, 5.25, 6.0])
    func acceptsInScaleValues(value: Double) {
        let grade = Fixture.grade(subjectId: 1, value: value)

        #expect(GradeValidator.validate(grade, in: education).isEmpty)
    }

    @Test("Rejects a value that isn't a number")
    func rejectsNonFiniteValue() {
        #expect(
            GradeValidator.validate(Fixture.grade(subjectId: 1, value: .nan), in: education)
                == [.valueOutOfRange(minimum: 1.0, maximum: 6.0)]
        )
    }

    @Test("Rejects a negative weight", arguments: [-1.0, -0.5])
    func rejectsNegativeWeight(weight: Double) {
        let grade = Fixture.grade(subjectId: 1, weight: weight)

        #expect(GradeValidator.validate(grade, in: education) == [.weightNegative])
    }

    /// A grade that is on the record without moving the average — a practice
    /// paper, a mark that was later dropped.
    @Test("Accepts a weight of zero")
    func acceptsZeroWeight() {
        let grade = Fixture.grade(subjectId: 1, weight: 0)

        #expect(GradeValidator.validate(grade, in: education).isEmpty)
    }

    @Test("Accepts a grade dated on either boundary of the education")
    func acceptsBoundaryDates() {
        let start = Fixture.grade(subjectId: 1, date: education.startDate)
        let end = Fixture.grade(subjectId: 1, date: education.endDate)

        #expect(GradeValidator.validate(start, in: education).isEmpty)
        #expect(GradeValidator.validate(end, in: education).isEmpty)
    }

    /// Rejected rather than clamped, same as the semester rule.
    @Test("Rejects a grade dated outside the education, instead of clamping it")
    func rejectsDatesOutsideEducation() {
        let before = Fixture.grade(subjectId: 1, date: .iso("2024-08-31"))
        let after = Fixture.grade(subjectId: 1, date: .iso("2027-09-01"))
        let expected = ValidationError.dateOutsideEducationRange(
            start: education.startDate,
            end: education.endDate
        )

        #expect(GradeValidator.validate(before, in: education) == [expected])
        #expect(GradeValidator.validate(after, in: education) == [expected])
        #expect(before.date == .iso("2024-08-31"))
    }

    @Test("Rejects any date when the education's own range is inverted")
    func rejectsWhenEducationRangeIsInverted() {
        let broken = Fixture.education(
            startDate: .iso("2026-09-01"),
            endDate: .iso("2026-08-31")
        )
        let grade = Fixture.grade(subjectId: 1, date: .iso("2026-08-31"))

        #expect(
            GradeValidator.validate(grade, in: broken)
                == [.dateOutsideEducationRange(start: broken.startDate, end: broken.endDate)]
        )
    }

    @Test("Caps the description at the shared limit")
    func capsDescriptionLength() {
        let grade = Fixture.grade(
            subjectId: 1,
            description: String(repeating: "a", count: ValidationLimits.maximumDescriptionLength + 1)
        )

        #expect(
            GradeValidator.validate(grade, in: education)
                == [.descriptionTooLong(maximum: ValidationLimits.maximumDescriptionLength)]
        )
    }

    @Test("Accepts a grade with no description at all")
    func acceptsNoDescription() {
        #expect(
            GradeValidator.validate(Fixture.grade(subjectId: 1, description: nil), in: education)
                .isEmpty
        )
    }

    @Test("Reports every broken rule together")
    func reportsAllErrors() {
        let grade = Fixture.grade(
            subjectId: 1,
            value: 0.0,
            weight: -1.0,
            date: .iso("2030-01-01")
        )

        let errors = GradeValidator.validate(grade, in: education)

        #expect(errors.count == 3)
        #expect(errors.contains(.weightNegative))
        #expect(errors.contains(.valueOutOfRange(minimum: 1.0, maximum: 6.0)))
        #expect(
            errors.contains(
                .dateOutsideEducationRange(start: education.startDate, end: education.endDate)
            )
        )
    }
}
