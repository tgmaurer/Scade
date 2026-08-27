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
