import SwiftUI

/// Spells out what deleting a subject takes with it (SPEC §4).
struct SubjectDeletionMessage: View {
    let name: String
    let gradeCount: Int

    var body: some View {
        if gradeCount == 0 {
            Text("\"\(name)\" will be deleted. This can't be undone.")
        } else {
            Text("\"\(name)\" will be deleted, along with ^[\(gradeCount) grade](inflect: true). This can't be undone.")
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        SubjectDeletionMessage(name: "Analysis", gradeCount: 0)
        SubjectDeletionMessage(name: "Analysis", gradeCount: 1)
        SubjectDeletionMessage(name: "Analysis", gradeCount: 7)
    }
    .padding()
}
