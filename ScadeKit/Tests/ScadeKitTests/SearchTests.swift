import Foundation
import Testing

@testable import ScadeKit

@Suite("Search (§3.5)")
struct SearchTests {

    private func education(
        _ name: String,
        description: String? = nil,
        institution: String? = nil
    ) -> Education {
        Fixture.education(name: name, description: description, institution: institution)
    }

    // MARK: - Empty queries

    @Test("An empty query matches everything", arguments: ["", " ", "\n", "  \t "])
    func emptyQueryMatchesEverything(query: String) {
        let educations = [education("Informatik"), education("Mathematik")]

        #expect(educations.matching(searchQuery: query).count == 2)
    }

    // MARK: - Case and accents

    @Test("Matches regardless of case")
    func matchesRegardlessOfCase() {
        let educations = [education("Informatik")]

        #expect(educations.matching(searchQuery: "informatik").count == 1)
        #expect(educations.matching(searchQuery: "INFORMATIK").count == 1)
        #expect(educations.matching(searchQuery: "InFoRmAtIk").count == 1)
    }

    /// The bug this whole approach exists to fix. SQLite's `NOCASE` collation
    /// is ASCII-only, so `LIKE '%über%'` never matched `Über` in the old app.
    @Test("Matches accented characters case-insensitively")
    func matchesAccentsCaseInsensitively() {
        let educations = [education("Übersetzen"), education("Pädagogik"), education("Ökonomie")]

        #expect(educations.matching(searchQuery: "über").count == 1)
        #expect(educations.matching(searchQuery: "ÜBER").count == 1)
        #expect(educations.matching(searchQuery: "pädagogik").count == 1)
        #expect(educations.matching(searchQuery: "ökonomie").count == 1)
    }

    /// A consequence of `localizedStandardContains`: an unaccented query
    /// still finds the accented word, which is what a search field is
    /// expected to do.
    @Test("Finds accented words from an unaccented query")
    func matchesAcrossDiacritics() {
        let educations = [education("Pädagogik"), education("Übersetzen")]

        #expect(educations.matching(searchQuery: "padagogik").count == 1)
        #expect(educations.matching(searchQuery: "ubersetzen").count == 1)
    }

    // MARK: - Fields

    @Test("Matches a substring anywhere in the name")
    func matchesSubstring() {
        let educations = [education("Angewandte Informatik")]

        #expect(educations.matching(searchQuery: "wandte").count == 1)
        #expect(educations.matching(searchQuery: "Informatik").count == 1)
    }

    @Test("Searches an education's name, description and institution")
    func searchesEducationFields() {
        let educations = [
            education("Informatik", description: "Bachelorstudium", institution: "ETH Zürich")
        ]

        #expect(educations.matching(searchQuery: "Informatik").count == 1)
        #expect(educations.matching(searchQuery: "bachelor").count == 1)
        #expect(educations.matching(searchQuery: "ETH").count == 1)
        #expect(educations.matching(searchQuery: "Basel").isEmpty)
    }

    @Test("Searches a subject's own name and description")
    func searchesSubjectFields() {
        let subjects = [
            Fixture.subject(educationId: 1, name: "Analysis", description: "Differentialrechnung")
        ]

        #expect(subjects.matching(searchQuery: "analys").count == 1)
        #expect(subjects.matching(searchQuery: "differential").count == 1)
        #expect(subjects.matching(searchQuery: "algebra").isEmpty)
    }

    @Test("Searches a subject's parent education by name")
    func searchesSubjectParent() {
        let items = [
            SubjectListItem(
                subject: Fixture.subject(educationId: 1, name: "Analysis"),
                education: education("Informatik", institution: "ETH Zürich")
            )
        ]

        #expect(items.matching(searchQuery: "Analysis").count == 1)
        #expect(items.matching(searchQuery: "Informatik").count == 1)
        #expect(items.matching(searchQuery: "Mathematik").isEmpty)
    }

    @Test("Searches a grade's description and both of its parents")
    func searchesGradeParents() {
        let items = [
            GradeListItem(
                grade: Fixture.grade(subjectId: 1, description: "Schlussprüfung"),
                subject: Fixture.subject(educationId: 1, name: "Analysis"),
                education: education("Informatik")
            )
        ]

        #expect(items.matching(searchQuery: "schluss").count == 1)
        #expect(items.matching(searchQuery: "Analysis").count == 1)
        #expect(items.matching(searchQuery: "Informatik").count == 1)
        #expect(items.matching(searchQuery: "Algebra").isEmpty)
    }

    @Test("Skips fields that aren't filled in")
    func toleratesMissingFields() {
        let educations = [education("Informatik", description: nil, institution: nil)]

        #expect(educations.matching(searchQuery: "Informatik").count == 1)
        #expect(educations.matching(searchQuery: "anything").isEmpty)
    }

    // MARK: - Behaviour

    @Test("Ignores whitespace around the query")
    func trimsQuery() {
        let educations = [education("Informatik")]

        #expect(educations.matching(searchQuery: "  Informatik  ").count == 1)
    }

    /// §3.6: the canonical order the repository applied is "unaffected by
    /// search", so filtering must not reorder anything.
    @Test("Keeps the order it was given")
    func preservesOrder() {
        let educations = [
            education("Informatik A"),
            education("Mathematik"),
            education("Informatik B"),
        ]

        let matches = educations.matching(searchQuery: "Informatik")

        #expect(matches.map(\.name) == ["Informatik A", "Informatik B"])
    }

    @Test("Returns nothing when nothing matches")
    func returnsNothingOnNoMatch() {
        let educations = [education("Informatik"), education("Mathematik")]

        #expect(educations.matching(searchQuery: "Geschichte").isEmpty)
    }
}

@Suite("CompletionFilter (§3.5)")
struct CompletionFilterTests {

    @Test("Lets everything through")
    func allMatchesEverything() {
        #expect(CompletionFilter.all.matches(completed: true))
        #expect(CompletionFilter.all.matches(completed: false))
    }

    @Test("Narrows to in-progress items")
    func inProgressExcludesCompleted() {
        #expect(CompletionFilter.inProgress.matches(completed: false))
        #expect(CompletionFilter.inProgress.matches(completed: true) == false)
    }

    @Test("Narrows to completed items")
    func completedExcludesInProgress() {
        #expect(CompletionFilter.completed.matches(completed: true))
        #expect(CompletionFilter.completed.matches(completed: false) == false)
    }

    @Test("Offers all three states to a picker")
    func offersEveryCase() {
        #expect(CompletionFilter.allCases == [.all, .inProgress, .completed])
    }
}
