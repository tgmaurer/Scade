import XCTest

/// End-to-end coverage for the flows SPEC-POLISH §0 calls out.
///
/// These exist because the polish phase is about to restyle every screen, and
/// a restyle can silently break a flow that still compiles. They drive the app
/// the way a person does — tap, type, save — and assert on what ends up on
/// screen, so a broken wire-up fails here rather than in someone's hands.
///
/// The domain rules themselves are pinned down by `ScadeKitTests`; what these
/// verify is that the UI is actually connected to them.
@MainActor // Potentially remove?
final class ScadeUITests: XCTestCase {

    /// Identifiers mirrored from `ScadeUI`'s `AccessibilityID`, which this
    /// target can't import. Change one, change the other.
    private enum ID {
        static let uiTesting = "-ui-testing"

        static let educationsSection = "sidebar.educations"
        static let subjectsSection = "sidebar.subjects"
        static let gradesSection = "sidebar.grades"

        static let save = "form.save"
        static let cancel = "form.cancel"
        static let error = "form.error"

        static let newEducation = "education.new"
        static let educationName = "education.form.name"

        static let newSubject = "subject.new"
        static let subjectName = "subject.form.name"
        static let subjectSemester = "subject.form.semester"

        static let newGrade = "grade.new"
        static let gradeValue = "grade.form.value"

        static let settingsSection = "sidebar.settings"
        static let deleteAll = "settings.deleteAll"
        static let confirmDeleteAll = "settings.deleteAll.confirm"
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        #if os(iOS)
        // Landscape keeps the split view's sidebar on screen, so section
        // switching doesn't depend on a disclosure button.
        XCUIDevice.shared.orientation = .landscapeLeft
        #endif

        app = XCUIApplication()
        // Without this the app opens the real database in Application
        // Support and these tests would edit the user's own records.
        app.launchArguments = [ID.uiTesting]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Flows

    /// The happy path, and the precondition for everything below it.
    func testCreatingAnEducationAddsItToTheList() {
        openSection(ID.educationsSection)
        createEducation(named: "Bachelor of Science")

        XCTAssertTrue(
            rowMentioning("Bachelor of Science").waitForExistence(timeout: 5),
            "A saved education should appear in the list."
        )
    }

    /// SPEC §3.4 chose visible field errors over the old app's silent clamp.
    /// An empty form must refuse to save and say why.
    func testSavingAnEmptyEducationShowsAnErrorAndKeepsTheFormOpen() {
        openSection(ID.educationsSection)
        tap(ID.newEducation)

        let save = app.buttons[ID.save]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        XCTAssertTrue(
            errorLabels.firstMatch.waitForExistence(timeout: 5),
            "An empty name should produce an inline validation error."
        )
        XCTAssertTrue(
            save.exists,
            "The form should stay open when validation fails."
        )
    }

    /// Cancelling must not write anything — the counterpart to the save path.
    func testCancellingAnEducationFormDiscardsIt() {
        openSection(ID.educationsSection)
        tap(ID.newEducation)

        type("Discarded", into: app.textFields[ID.educationName])
        app.buttons[ID.cancel].tap()

        XCTAssertFalse(
            rowMentioning("Discarded").waitForExistence(timeout: 2),
            "A cancelled form should not create a record."
        )
    }

    /// §3.4 again, and the rule most likely to regress: a semester past the
    /// education's own count is rejected, not quietly clamped down to fit.
    func testSubjectSemesterBeyondTheEducationIsRejected() {
        openSection(ID.educationsSection)
        // The default semester count on create is 2 (§4).
        createEducation(named: "Two Semester Course")

        openSection(ID.subjectsSection)
        tap(ID.newSubject)

        type("Impossible Semester", into: app.textFields[ID.subjectName])
        replaceText("7", in: app.textFields[ID.subjectSemester])
        app.buttons[ID.save].tap()

        XCTAssertTrue(
            errorLabels.firstMatch.waitForExistence(timeout: 5),
            "Semester 7 of a 2-semester education should be refused."
        )
        XCTAssertTrue(
            app.buttons[ID.save].exists,
            "The form should stay open rather than clamping the value."
        )
    }

    /// The one test that reaches all the way through: a grade entered in the
    /// UI should show up as that subject's average, which means the form, the
    /// repositories and `GradeCalculator` are genuinely wired together.
    func testAGradeShowsUpInTheSubjectAverage() {
        openSection(ID.educationsSection)
        createEducation(named: "Averages Course")

        openSection(ID.subjectsSection)
        createSubject(named: "Statistics")

        openSection(ID.gradesSection)
        tap(ID.newGrade)
        replaceText("5", in: app.textFields[ID.gradeValue])
        app.buttons[ID.save].tap()

        openSection(ID.subjectsSection)
        XCTAssertTrue(
            rowMentioning("5.00").waitForExistence(timeout: 5),
            "A single grade of 5 should read as a 5.00 average (§3.1, §3.3)."
        )
    }

    /// The only destructive action that isn't scoped to one record, so the
    /// one most worth pinning down: it has to actually empty the database,
    /// and it has to be reachable only through the confirmation.
    func testDeletingAllDataEmptiesTheList() {
        openSection(ID.educationsSection)
        createEducation(named: "Doomed Course")
        XCTAssertTrue(rowMentioning("Doomed Course").waitForExistence(timeout: 5))

        openSection(ID.settingsSection)
        tap(ID.deleteAll)
        tap(ID.confirmDeleteAll)

        openSection(ID.educationsSection)
        XCTAssertFalse(
            rowMentioning("Doomed Course").waitForExistence(timeout: 3),
            "Deleting all data should remove every education."
        )
    }

    // MARK: - Helpers

    /// Matches on any element type, because a `Label`'s rendered element kind
    /// isn't guaranteed across platforms.
    private var errorLabels: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: ID.error)
    }

    /// Finds a list row by something written in it.
    ///
    /// macOS collapses a row into a single element whose label concatenates
    /// everything in it — "Bachelor of Science, N/A, 2026–2027, …" — while iOS
    /// exposes each `Text` separately. "Some element mentions this" is the
    /// only phrasing that's true on both, so these tests never assert on an
    /// exact row label; that would just pin down today's row layout, which
    /// the polish phase is about to change anyway.
    private func rowMentioning(_ text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    private func openSection(_ identifier: String) {
        let row = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Sidebar row \(identifier) never appeared.")
        row.tap()
    }

    /// Taps the one button a person would tap.
    ///
    /// A subscript lookup insists on a single match, which iOS breaks for
    /// confirmation dialogs — it renders the dialog's buttons more than once
    /// and only one copy is on screen. Picking the hittable match says what
    /// we actually mean, and behaves the same when there's only one.
    private func tap(_ identifier: String) {
        let matches = app.buttons.matching(identifier: identifier)
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 10), "Button \(identifier) never appeared.")

        let target = matches.allElementsBoundByIndex.first(where: \.isHittable) ?? matches.firstMatch
        target.tap()
    }

    private func createEducation(named name: String) {
        tap(ID.newEducation)
        type(name, into: app.textFields[ID.educationName])
        app.buttons[ID.save].tap()
    }

    private func createSubject(named name: String) {
        tap(ID.newSubject)
        type(name, into: app.textFields[ID.subjectName])
        app.buttons[ID.save].tap()
    }

    private func type(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    /// Numeric fields arrive prefilled, so typing alone would append.
    ///
    /// Selecting rather than counting: a plain tap only places the caret, and
    /// where it lands differs by platform, while the existing length can't be
    /// measured reliably either — `value` is a formatted string on iOS but a
    /// number on macOS. A double tap selects what's there on both, and typing
    /// over a selection replaces it.
    private func replaceText(_ text: String, in field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.doubleTap()
        field.typeText(text)
    }
}
