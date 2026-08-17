#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The subjects list is a column of rows, so what matters is that they're all
/// the same shape: two lines, whatever is written in them.
///
/// Rows of differing heights read as differing *kinds* of row — the fault
/// §2.5 states for Home's cards, and the same one here. Measured by rendering,
/// which is the only way to see it: every one of these renders all the right
/// words and passes every flow test.
@MainActor
struct SubjectRowLayoutTests {
    /// The narrowest the window goes, less the margins a row sits inside.
    private let narrowest = ScadeDesign.minimumWindowWidth
        - ScadeDesign.sidebarWidth
        - 2 * ScadeDesign.contentMargin

    private func height(_ row: SubjectRow, width: Double) throws -> Double {
        let renderer = ImageRenderer(content: SubjectRowView(row: row).frame(width: width))
        return try #require(renderer.nsImage).size.height
    }

    private var plain: SubjectRow { PreviewData.subjectRow(name: "Analysis") }

    /// A subject with no grades has no average, and "N/A" is a different
    /// width from "4.50" — it must not be a different height.
    @Test(arguments: [500.0, 900.0, 1400.0])
    func aSubjectWithoutGradesIsTheSameHeight(width: Double) throws {
        let none = PreviewData.subjectRow(name: "Analysis", grades: [])

        #expect(try height(none, width: width) == height(plain, width: width))
    }

    /// The weight only appears when it isn't the default, so the row has one
    /// more thing in it sometimes. That must not move the row either.
    @Test(arguments: [500.0, 900.0, 1400.0])
    func aWeightedSubjectIsTheSameHeight(width: Double) throws {
        let weighted = PreviewData.subjectRow(name: "Analysis", weight: 1.5)

        #expect(try height(weighted, width: width) == height(plain, width: width))
    }

    /// And completing one swaps its badge for a wider one.
    @Test(arguments: [500.0, 900.0, 1400.0])
    func aCompletedSubjectIsTheSameHeight(width: Double) throws {
        let completed = PreviewData.subjectRow(name: "Analysis", completed: true)

        #expect(try height(completed, width: width) == height(plain, width: width))
    }

    /// The squeeze guard, and the one that would have caught the educations
    /// bug a screenshot found instead: a name long enough to fill the row must
    /// truncate rather than wrap, at the narrowest width the window allows.
    @Test func aVeryLongNameDoesNotMakeTheRowTaller() throws {
        let long = PreviewData.subjectRow(
            name: String(repeating: "a", count: ValidationLimits.maximumNameLength)
        )

        #expect(try height(long, width: narrowest) == height(plain, width: narrowest))
    }

    /// The same for the education underneath it, which is a separate line with
    /// its own limit and so can drift on its own.
    @Test func aVeryLongEducationNameDoesNotMakeTheRowTaller() throws {
        var education = PreviewData.education(
            name: String(repeating: "b", count: ValidationLimits.maximumNameLength)
        )
        education.id = 1

        var subject = Subject(educationId: 1, name: "Analysis", semester: 3)
        subject.id = 1

        let long = SubjectRow(
            SubjectSummary(subject: subject, education: education, grades: [])
        )
        let short = PreviewData.subjectRow(name: "Analysis", grades: [])

        #expect(try height(long, width: narrowest) == height(short, width: narrowest))
    }
}
#endif
