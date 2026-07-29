import SwiftUI

/// Spells out what a cascade delete will take with it (SPEC §4).
///
/// Shared by the list and the detail screen so the warning can't drift
/// between them, and inflected so the count reads correctly at one.
struct EducationDeletionMessage: View {
    let name: String
    let subjectCount: Int

    var body: some View {
        if subjectCount == 0 {
            Text("\"\(name)\" will be deleted. This can't be undone.")
        } else {
            Text("\"\(name)\" will be deleted, along with ^[\(subjectCount) subject](inflect: true) and every grade in them. This can't be undone.")
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        EducationDeletionMessage(name: "Informatik", subjectCount: 0)
        EducationDeletionMessage(name: "Informatik", subjectCount: 1)
        EducationDeletionMessage(name: "Informatik", subjectCount: 4)
    }
    .padding()
}
