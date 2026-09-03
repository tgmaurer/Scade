import SwiftUI

/// What Scade is, and the handful of things worth explaining about it.
///
/// **The two links take the pointing hand**, which SPEC-POLISH §2.8 keeps
/// away from everything else in the app. That rule is about in-app
/// navigation, where the hand promises a browser that never opens; these two
/// genuinely leave for one, which is the case macOS reserves it for.
struct AboutSection: View {
    /// Scade's own repository: the only place a copy of the app comes from.
    private static let repository = URL(string: "https://github.com/tgmaurer/Scade")!

    /// The database library the whole persistence layer is built on.
    private static let grdb = URL(string: "https://github.com/groue/GRDB.swift")!

    private var version: String {
        let bundle = Bundle.main
        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String

        return switch (short, build) {
        case (let short?, let build?): "\(short) (\(build))"
        case (let short?, nil): short
        default: "—"
        }
    }

    var body: some View {
        Section("About") {
            LabeledContent("Version", value: version)
            LabeledContent("Licence", value: "GPL-3.0")

            // The repository is where the licence is honoured, where a build
            // comes from and where a bug goes — this app has no download page
            // and no other way of reaching any of that.
            LabeledContent("Source") {
                Link("github.com/tgmaurer/Scade", destination: Self.repository)
                    // `PointerStyle` is macOS-only — there is no iOS version
                    // to fall back to, so the call compiles out entirely.
                    #if os(macOS)
                    .pointerStyle(.link)
                    #endif
            }

            // GRDB is the only dependency Scade has, and it earns a line
            // here rather than only in the README: the app is the thing
            // people run, and this is where its credits are legible. The
            // link goes to the licence itself, which is where MIT's notice
            // actually lives.
            LabeledContent("Built With") {
                Link("GRDB.swift (MIT)", destination: Self.grdb)
                    #if os(macOS)
                    .pointerStyle(.link)
                    #endif
            }
        }

        Section("How Grades Work") {
            AboutEntry(
                question: "How is a subject's average calculated?",
                answer: "Each grade counts according to its weight. A grade at 50% moves the average half as much as one at 100%."
            )
            AboutEntry(
                question: "How is an education's average calculated?",
                answer: "Each subject's average counts according to the subject's weight. Subjects without any grades are left out entirely rather than counted as zero."
            )
            AboutEntry(
                question: "Why does an average show N/A?",
                answer: "Nothing has been graded yet — or nothing that has been graded counts, because every grade is weighted 0%. Either way that's different from a zero, so Scade doesn't pretend otherwise."
            )
            AboutEntry(
                question: "What does a weight of 0% do?",
                answer: "Keeps the grade or subject on the record without letting it move any average. Useful for a practice paper, or a subject you sit that carries no marks."
            )
            AboutEntry(
                question: "Which grades count as failing?",
                answer: "Anything below 4, on the Swiss 1–6 scale. Failing grades and averages are marked in red, with an icon when Differentiate Without Color is on."
            )
        }
    }
}

#Preview {
    Form {
        AboutSection()
    }
}
