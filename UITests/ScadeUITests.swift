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
/// Main-actor because the target builds in Swift 6 language mode and
/// `XCUIApplication` is main-actor isolated; without it every helper below
/// needs its own annotation.
@MainActor
final class ScadeUITests: XCTestCase {

    /// An element addressed two ways, because the identifier doesn't always
    /// survive to the rendered control: macOS draws sidebar rows in AppKit,
    /// and iOS re-renders toolbar items that overflow into a "More" menu.
    /// Both keep the visible label, so it's the fallback.
    private struct Control {
        let identifier: String
        let label: String

        init(_ identifier: String, _ label: String) {
            self.identifier = identifier
            self.label = label
        }
    }

    /// Identifiers mirrored from `ScadeUI`'s `AccessibilityID`, which this
    /// target can't import. Change one, change the other.
    private enum ID {
        static let uiTesting = "-ui-testing"

        static let homeSection = Control("section.home", "Home")
        static let educationsSection = Control("section.educations", "Educations")
        static let subjectsSection = Control("section.subjects", "Subjects")
        static let gradesSection = Control("section.grades", "Grades")

        static let save = Control("form.save", "Save")
        static let cancel = Control("form.cancel", "Cancel")
        static let error = "form.error"

        static let newEducation = Control("education.new", "New Education")
        static let educationDetail = "education.detail"
        static let educationName = "education.form.name"

        static let newSubject = Control("subject.new", "New Subject")
        static let subjectName = "subject.form.name"
        static let subjectSemester = "subject.form.semester"
        static let subjectDetail = "subject.detail"
        static let editSubject = Control("subject.edit", "Edit")

        static let newGrade = Control("grade.new", "New Grade")
        static let gradeValue = "grade.form.value"

        static let settingsSection = Control("section.settings", "Settings")
        static let openSettings = Control("settings.open", "Settings")
        static let deleteAll = Control("settings.deleteAll", "Delete All Data")
        static let confirmDeleteAll = Control("settings.deleteAll.confirm", "Delete Everything")
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // No orientation forcing: the shell is a `TabView` now, and its tabs
        // are on screen in both orientations. The split view this replaced
        // hid its sidebar in portrait, which is why these tests used to run
        // in landscape.

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

        tap(ID.save)

        XCTAssertTrue(
            errorLabels.firstMatch.waitForExistence(timeout: 5),
            "An empty name should produce an inline validation error."
        )
        XCTAssertTrue(
            app.buttons[ID.save.identifier].exists,
            "The form should stay open when validation fails."
        )
    }

    /// Cancelling must not write anything — the counterpart to the save path.
    func testCancellingAnEducationFormDiscardsIt() {
        openSection(ID.educationsSection)
        tap(ID.newEducation)

        type("Discarded", into: app.textFields[ID.educationName])
        tap(ID.cancel)

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
        tap(ID.save)

        XCTAssertTrue(
            errorLabels.firstMatch.waitForExistence(timeout: 5),
            "Semester 7 of a 2-semester education should be refused."
        )
        XCTAssertTrue(
            app.buttons[ID.save.identifier].exists,
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
        tap(ID.save)

        openSection(ID.subjectsSection)
        XCTAssertTrue(
            rowMentioning("5.00").waitForExistence(timeout: 5),
            "A single grade of 5 should read as a 5.00 average (§3.1, §3.3)."
        )
    }

    /// Home's rows navigate.
    ///
    /// This exists because they once silently stopped. The subject name and
    /// the grade chips are `Button`s that push a path rather than
    /// `NavigationLink`s (see `Navigator`), and nothing else in this suite
    /// would notice if that wiring came undone — every other test reaches a
    /// detail screen through one of the flat lists, which push a different
    /// way. The app still built, still launched, and still drew the row.
    func testTappingASubjectOnHomeOpensIt() {
        openSection(ID.educationsSection)
        createEducation(named: "Navigable Course")

        openSection(ID.subjectsSection)
        createSubject(named: "Databases")

        openSection(ID.homeSection)
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Databases"))
            .firstMatch
            .tap()

        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: ID.subjectDetail)
                .firstMatch
                .waitForExistence(timeout: 5),
            "Clicking a subject's name on Home should open its detail screen."
        )
    }

    /// An education in the list opens when you click it.
    ///
    /// Trivial while the list was a `List` — a row pushed because that's what
    /// a `NavigationLink` in a row does, and no test needed to say so. It
    /// stopped being trivial when macOS moved to a grid of tiles: the tile is
    /// a `Button` with `.buttonStyle(.plain)` and a `contentShape` deciding
    /// what counts as a click, and every one of those is a way to draw a card
    /// that looks right and doesn't navigate. Home's rows made that exact
    /// mistake once already.
    func testTappingAnEducationInTheListOpensIt() {
        openSection(ID.educationsSection)
        createEducation(named: "Openable Course")

        rowMentioning("Openable Course").tap()

        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: ID.educationDetail)
                .firstMatch
                .waitForExistence(timeout: 5),
            "Clicking an education should open its detail screen."
        )
    }

    /// Switching section works from inside a section, not just at its root.
    ///
    /// A `NavigationStack`'s path outlives a change of its root, so the macOS
    /// shell sharing one stack across every section meant switching section
    /// swapped the root *underneath* whatever was pushed on top of it — the
    /// sidebar looked dead until you navigated back. Every other test in this
    /// file switches section from a list, which is the one case that worked.
    func testSwitchingSectionFromADetailScreenLeavesIt() {
        openSection(ID.educationsSection)
        createEducation(named: "Deep Course")

        openSection(ID.subjectsSection)
        createSubject(named: "Compilers")

        openSection(ID.homeSection)
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Compilers"))
            .firstMatch
            .tap()
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: ID.subjectDetail)
                .firstMatch
                .waitForExistence(timeout: 5),
            "Precondition: the subject detail should be open."
        )

        openSection(ID.educationsSection)

        XCTAssertTrue(
            rowMentioning("Deep Course").waitForExistence(timeout: 5),
            "Choosing a section from a pushed screen should land on that section."
        )
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: ID.subjectDetail)
                .firstMatch
                .exists,
            "The pushed screen should be gone, not left sitting on top."
        )
    }

    /// A list shows an edit made on the detail screen it pushed.
    ///
    /// Screens load in `onAppear`, which doesn't run again when a pushed
    /// screen is popped, so a list could sit showing a record that had since
    /// been renamed underneath it.
    func testRenamingASubjectOnItsDetailUpdatesTheListBehindIt() {
        openSection(ID.educationsSection)
        createEducation(named: "Refresh Course")

        openSection(ID.subjectsSection)
        createSubject(named: "Before Rename")

        rowMentioning("Before Rename").tap()
        XCTAssertTrue(subjectDetail.waitForExistence(timeout: 5))

        tap(ID.editSubject)
        replaceText("After Rename", in: app.textFields[ID.subjectName])
        tap(ID.save)

        goBack()

        XCTAssertTrue(
            rowMentioning("After Rename").waitForExistence(timeout: 5),
            "The list should show the renamed subject once the detail is closed."
        )
    }



    /// The only destructive action that isn't scoped to one record, so the
    /// one most worth pinning down: it has to actually empty the database,
    /// and it has to be reachable only through the confirmation.
    func testDeletingAllDataEmptiesTheList() {
        openSection(ID.educationsSection)
        createEducation(named: "Doomed Course")
        XCTAssertTrue(rowMentioning("Doomed Course").waitForExistence(timeout: 5))

        openSettings()
        tap(ID.deleteAll)
        tap(ID.confirmDeleteAll)
        closeSettings()

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

    /// The subject detail screen, as a way of asking whether a push happened —
    /// the subject's *name* is on the screen the push started from too.
    private var subjectDetail: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: ID.subjectDetail)
            .firstMatch
    }

    /// Pops the pushed screen, the way a person would.
    ///
    /// macOS gives its back button the chevron's symbol name as an
    /// identifier; iOS labels its own with the *previous screen's* title, so
    /// there the navigation bar's first button is the only portable handle.
    private func goBack() {
        let chevron = app.buttons["chevron.backward"]
        if chevron.waitForExistence(timeout: 3) {
            chevron.tap()
            return
        }

        let first = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5), "No back button on the pushed screen.")
        first.tap()
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

    /// Switches shell section — a tab on iOS, a sidebar row on macOS.
    ///
    /// Matched on identifier *or* label, because the shells differ in what
    /// they keep. macOS draws its sidebar rows itself and keeps the
    /// identifier; iPhone's tab bar is system-drawn and keeps only the label.
    /// Element type isn't pinned for the same reason — a sidebar row and a tab
    /// don't report as the same thing.
    private func openSection(_ section: Control) {
        let matches = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@ OR label == %@", section.identifier, section.label)
        )

        XCTAssertTrue(
            matches.firstMatch.waitForExistence(timeout: 10),
            "Section \(section.label) never appeared."
        )

        let target = matches.allElementsBoundByIndex.first(where: \.isHittable) ?? matches.firstMatch
        target.tap()
    }

    /// Taps the one button a person would tap.
    ///
    /// A subscript lookup insists on a single match, which iOS breaks for
    /// confirmation dialogs — it renders the dialog's buttons more than once
    /// and only one copy is on screen. Picking the hittable match says what
    /// we actually mean, and behaves the same when there's only one.
    ///
    /// If nothing turns up, the toolbar's overflow menu is opened and the
    /// search repeated — see `openToolbarOverflow()`.
    private func tap(_ control: Control) {
        let byIdentifier = app.buttons.matching(identifier: control.identifier)

        if byIdentifier.firstMatch.waitForExistence(timeout: 5) == false {
            openToolbarOverflow()
        }

        // The overflow menu rebuilds its items and drops the identifier on
        // the way, so inside it the label is all there is.
        let matches = byIdentifier.firstMatch.exists
            ? byIdentifier
            : app.buttons.matching(NSPredicate(format: "label == %@", control.label))

        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 10), "Button \(control.label) never appeared.")

        let target = matches.allElementsBoundByIndex.first(where: \.isHittable) ?? matches.firstMatch
        target.tap()
    }

    /// Opens Settings, which each platform offers differently: a sidebar row
    /// on macOS, and everywhere else a button on Home, because Settings has no
    /// section of its own there. See `AppSection.showsSettingsSection`.
    private func openSettings() {
        #if os(macOS)
        openSection(ID.settingsSection)
        #else
        openSection(ID.homeSection)
        tap(ID.openSettings)
        #endif
    }

    /// Dismisses the Settings sheet, where there was one to dismiss. On macOS
    /// Settings is a section rather than a sheet, so there's nothing to close.
    private func closeSettings() {
        #if os(iOS)
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "The Settings sheet should have a Done button.")
        done.tap()
        #endif
    }

    /// Opens the "More" menu iOS collapses overflowing toolbar items into.
    ///
    /// An 11-inch iPad in portrait doesn't have room for a search field and
    /// three toolbar buttons, so most of them end up here. The button is still
    /// reachable, just one tap further away — which is what a person would
    /// have to do too, so the test does the same rather than forcing an
    /// orientation that hides the problem.
    private func openToolbarOverflow() {
        let overflow = app.buttons["OverflowBarButtonItem"]
        guard overflow.exists else { return }

        overflow.tap()
    }

    private func createEducation(named name: String) {
        tap(ID.newEducation)
        type(name, into: app.textFields[ID.educationName])
        tap(ID.save)
    }



    private func createSubject(named name: String) {
        tap(ID.newSubject)
        type(name, into: app.textFields[ID.subjectName])
        tap(ID.save)
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
