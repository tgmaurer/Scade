import SwiftUI

/// Whether an education or subject is finished.
///
/// The icon changes with the state as well as the colour, so this reads
/// correctly without relying on green-versus-grey.
struct CompletionBadge: View {
    let isCompleted: Bool

    init(isCompleted: Bool) {
        self.isCompleted = isCompleted
    }

    var body: some View {
        Label(
            isCompleted ? "Completed" : "In Progress",
            systemImage: isCompleted ? "checkmark.circle.fill" : "clock"
        )
        .foregroundStyle(isCompleted ? Color.green : Color.secondary)
    }
}

#Preview {
    VStack(alignment: .leading) {
        CompletionBadge(isCompleted: false)
        CompletionBadge(isCompleted: true)
    }
    .padding()
}
