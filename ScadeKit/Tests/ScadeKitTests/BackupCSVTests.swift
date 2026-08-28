import Foundation
import Testing

@testable import ScadeKit

@Suite("Backup — CSV")
struct BackupCSVTests {

    // MARK: - Escaping

    @Test("Leaves a plain field alone")
    func plainField() {
        #expect(CSV.field("Analysis") == "Analysis")
    }

    @Test("Quotes a field holding the separator")
    func fieldWithComma() {
        #expect(CSV.field("gibb, Bern") == "\"gibb, Bern\"")
    }

    @Test("Doubles a quote inside a field, and quotes the field")
    func fieldWithQuote() {
        #expect(CSV.field("the \"hard\" one") == "\"the \"\"hard\"\" one\"")
    }

    @Test("Quotes a field holding a line break")
    func fieldWithNewline() {
        #expect(CSV.field("first\nsecond") == "\"first\nsecond\"")
    }

    @Test("A number reads the same in every locale")
    func numberIsLocaleIndependent() {
        #expect(CSV.number(0.625) == "0.625")
    }

    // MARK: - Documents

    @Test("A document starts with the byte order mark and ends with a break")
    func documentShape() {
        let text = CSV.document(header: ["a", "b"], rows: [["1", "2"]])

        #expect(text.hasPrefix(CSV.byteOrderMark))
        #expect(text.hasSuffix(CSV.lineBreak))
        #expect(text.contains("a,b\r\n1,2"))
    }

    @Test("An empty table is still a header")
    func emptyTable() {
        let text = BackupTables.grades([])

        #expect(text == CSV.byteOrderMark + "id,subjectId,value,weight,description,date,updatedAt\r\n")
    }

    // MARK: - Tables

    @Test("An education row carries every stored column")
    func educationRow() throws {
        var education = Fixture.education(
            name: "Informatiker EFZ",
            description: "Four years",
            institution: "gibb, Bern"
        )
        education.id = 7

        let lines = BackupTables.educations([education])
            .components(separatedBy: CSV.lineBreak)

        // The institution holds a comma, so it has to arrive quoted.
        #expect(lines[1].hasPrefix("7,Informatiker EFZ,\"gibb, Bern\",Four years,6,"))
        #expect(lines[1].contains(",2024-09-01,2027-08-31,false,"))
    }

    @Test("A missing description is an empty field, not the word nil")
    func absentDescription() throws {
        var subject = Fixture.subject(educationId: 1, name: "Math", weight: 0.5)
        subject.id = 3

        let lines = BackupTables.subjects([subject])
            .components(separatedBy: CSV.lineBreak)

        #expect(lines[1].hasPrefix("3,1,Math,,1,0.5,false,"))
    }

    @Test("A grade keeps its stored value and weight")
    func gradeRow() throws {
        var grade = Fixture.grade(subjectId: 4, value: 5.25, weight: 0.25, date: .iso("2026-08-27"))
        grade.id = 9

        let lines = BackupTables.grades([grade])
            .components(separatedBy: CSV.lineBreak)

        #expect(lines[1].hasPrefix("9,4,5.25,0.25,,2026-08-27,"))
    }
}

/// The flat sheet that spells the parents out on every row.
///
/// What these pin is the reason it can exist alongside the normalised three
/// rather than instead of them: it is a left join, so nothing childless
/// disappears from it.
@Suite("Backup — overview sheet")
struct BackupOverviewTests {

    private func summary(
        education: String,
        institution: String? = nil,
        subjects: [SubjectGrades]
    ) -> EducationSummary {
        EducationSummary(
            education: Education(
                id: 1,
                name: education,
                semesters: 8,
                startDate: .iso("2024-08-01") ?? .today(),
                endDate: .iso("2028-07-31") ?? .today(),
                institution: institution
            ),
            subjects: subjects
        )
    }

    private func lines(_ document: String) -> [String] {
        document
            .replacingOccurrences(of: CSV.byteOrderMark, with: "")
            .components(separatedBy: CSV.lineBreak)
            .filter { $0.isEmpty == false }
    }

    @Test("Names its columns, parents first")
    func header() {
        let header = lines(BackupTables.overview([])).first

        #expect(
            header == "education,institution,educationAverage,semester,subject,"
                + "subjectWeight,subjectAverage,date,grade,gradeWeight,gradeDescription"
        )
    }

    @Test("Writes one row per grade, with its subject and education on it")
    func oneRowPerGrade() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                institution: "gibb, Bern",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "Math", semester: 2),
                        grades: [
                            Fixture.grade(subjectId: 1, value: 5.0, date: .iso("2026-03-01")),
                            Fixture.grade(subjectId: 1, value: 4.0, weight: 0.5, date: .iso("2026-04-01")),
                        ]
                    )
                ]
            )
        ])

        let rows = lines(sheet).dropFirst()

        #expect(rows.count == 2)
        #expect(
            rows.first
                == "Informatiker EFZ,\"gibb, Bern\",4.67,2,Math,1.0,"
                + "4.67,2026-03-01,5.0,1.0,"
        )
    }

    /// The whole reason a flat sheet was once ruled out. A left join keeps
    /// it, so the objection doesn't apply.
    @Test("Keeps a subject that has no grades")
    func keepsUngradedSubject() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "English", semester: 3),
                        grades: []
                    )
                ]
            )
        ])

        let rows = lines(sheet).dropFirst()

        #expect(rows.count == 1)
        #expect(rows.first == "Informatiker EFZ,,,3,English,1.0,,,,,")
    }

    @Test("Keeps an education that has no subjects")
    func keepsEmptyEducation() {
        let sheet = BackupTables.overview([
            summary(education: "Some Education", institution: "Somewhere", subjects: [])
        ])

        let rows = lines(sheet).dropFirst()

        #expect(rows.count == 1)
        #expect(rows.first == "Some Education,Somewhere,,,,,,,,,")
    }

    /// An average that isn't there is an empty cell, never a zero — the same
    /// distinction the screens draw with N/A.
    @Test("Leaves an absent average blank rather than writing zero")
    func absentAverageIsBlank() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "English"),
                        grades: []
                    )
                ]
            )
        ])

        let row = try? #require(lines(sheet).dropFirst().first)
        #expect(row?.contains("0.0") == false)
    }

    /// A subject at 0% counts for nothing, so an education made only of them
    /// has no average — and the cell is empty rather than zero.
    @Test("Leaves the education average blank when nothing counts")
    func zeroWeightEducationHasNoAverage() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "Sport", weight: 0),
                        grades: [Fixture.grade(subjectId: 1, value: 5.0)]
                    )
                ]
            )
        ])

        let row = lines(sheet).dropFirst().first ?? ""

        // education,institution,educationAverage → the third field is empty.
        #expect(row.hasPrefix("Informatiker EFZ,,,"))
    }

    /// The stored columns keep full precision; only the two computed ones
    /// round. A weight of 66.7% is `0.667` in the file, not `0.67`.
    @Test("Rounds the averages but not the stored values")
    func roundsOnlyTheAverages() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "Math", weight: 0.667),
                        grades: [Fixture.grade(subjectId: 1, value: 5.0, weight: 0.333)]
                    )
                ]
            )
        ])

        // No field in this row holds a comma, so a plain split is the row.
        let fields = (lines(sheet).dropFirst().first ?? "").components(separatedBy: ",")

        #expect(fields[5] == "0.667")   // subjectWeight, stored in full
        #expect(fields[9] == "0.333")   // gradeWeight, stored in full
        #expect(fields[8] == "5.0")     // the grade itself, stored in full
        #expect(fields[6] == "5.00")    // subjectAverage, rounded like the app
    }

    @Test("Escapes a description holding the separator")
    func escapesDescription() {
        let sheet = BackupTables.overview([
            summary(
                education: "Informatiker EFZ",
                subjects: [
                    SubjectGrades(
                        subject: Fixture.subject(educationId: 1, name: "Math"),
                        grades: [
                            Fixture.grade(
                                subjectId: 1,
                                value: 5.0,
                                description: "Prüfung 1, Teil 2"
                            )
                        ]
                    )
                ]
            )
        ])

        #expect(lines(sheet).dropFirst().first?.hasSuffix("\"Prüfung 1, Teil 2\"") == true)
    }
}
