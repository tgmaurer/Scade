import ScadeKit
import SwiftUI

/// Confirms deleting a grade. Nothing cascades from here, so this just names
/// what's going.
struct GradeDeletionMessage: View {
    let item: GradeListItem

    var body: some View {
        Text("The grade \(item.grade.value.formatted(GradeFormatter.valueStyle)) in \"\(item.subject.name)\" will be deleted. This can't be undone.")
    }
}
