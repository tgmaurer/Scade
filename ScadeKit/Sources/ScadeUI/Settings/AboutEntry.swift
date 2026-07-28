import SwiftUI

/// One question and answer in the about section.
struct AboutEntry: View {
    let question: LocalizedStringKey
    let answer: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: ScadeDesign.iconTextSpacing) {
            Text(question)
                .font(.subheadline)
                .bold()

            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, ScadeDesign.iconTextSpacing)
    }
}

#Preview {
    Form {
        AboutEntry(
            question: "Why does an average show N/A?",
            answer: "Nothing has been graded yet."
        )
    }
}
