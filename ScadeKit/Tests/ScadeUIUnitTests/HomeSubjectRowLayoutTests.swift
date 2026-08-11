#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// Layout regressions on the dashboard row, measured by rendering it.
///
/// This exists because the row's layout broke twice in a way nothing else
/// could see. The app built, launched, passed every flow test and drew
/// something — it was just the wrong shape, and only a screenshot showed it.
/// Both failures moved the row's *height*, so that's what's pinned here.
///
/// `ImageRenderer` gives a real SwiftUI layout pass without a window, which is
/// the cheapest way to assert on geometry. It measures the row alone, not the
/// `List` around it: the faults were in the row's own stack, and rendering
/// list chrome headlessly buys nothing.
@MainActor
struct HomeSubjectRowLayoutTests {
    /// The height of one row at a given width.
    private func height(of item: HomeSubject, width: Double) throws -> Double {
        let renderer = ImageRenderer(
            content: HomeSubjectRow(item: item, showsGrades: true).frame(width: width)
        )
        return try #require(renderer.nsImage).size.height
    }

    private var withGrades: HomeSubject {
        HomeSubject(SubjectGrades(
            subject: Subject(educationId: 1, name: "Module 404", semester: 2),
            grades: [
                Grade(id: 1, subjectId: 1, value: 3.5, date: .today()),
                Grade(id: 2, subjectId: 1, value: 5.0, weight: 0.5, date: .today()),
                Grade(id: 3, subjectId: 1, value: 6.0, weight: 0.5, date: .today()),
            ]
        ))
    }

    private var withoutGrades: HomeSubject {
        HomeSubject(SubjectGrades(
            subject: Subject(educationId: 1, name: "Module 123", semester: 2),
            grades: []
        ))
    }

    /// A subject with no grades has no chips to give its row height, and used
    /// to sit shorter than its neighbours. Two heights in one card read as two
    /// kinds of row.
    @Test(arguments: [740.0, 900.0, 1200.0])
    func rowsAreTheSameHeightWithAndWithoutGrades(width: Double) throws {
        #expect(try height(of: withGrades, width: width) == height(of: withoutGrades, width: width))
    }

    /// The row is one line, whatever is in it.
    ///
    /// This is the squeeze guard. When something in the row claimed an
    /// infinite ideal width — a `Spacer` beside the subject button, both times
    /// — everything after it was left near-zero width: the chips wrapped one
    /// per line, "No grades yet" wrapped to a tall invisible column, and the
    /// average vanished off the edge. Every symptom was a much taller row, so
    /// a ceiling catches the whole family.
    @Test(arguments: [740.0, 900.0, 1200.0])
    func rowStaysOneLineHigh(width: Double) throws {
        let ceiling = ScadeDesign.subjectRowHeight * 1.5

        #expect(try height(of: withGrades, width: width) < ceiling)
        #expect(try height(of: withoutGrades, width: width) < ceiling)
    }
}
#endif
