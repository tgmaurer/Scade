import SwiftUI

/// What Scade is, and the handful of things worth explaining about it.
struct AboutSection: View {
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
                answer: "Nothing has been graded yet. That's different from a zero, so Scade doesn't pretend otherwise."
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
