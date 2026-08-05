import ScadeKit
import SwiftUI

/// Backs the grade detail screen.
@Observable
final class GradeDetailModel {
    private(set) var item: GradeListItem?

    var isConfirmingDeletion = false
    var errorMessage: String?
    private(set) var wasDeleted = false

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if newValue == false { errorMessage = nil } }
    }

    func load(id: Int64?, from repositories: Repositories) {
        guard let id else { return }

        do {
            item = try repositories.grades.listItem(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDeletion(from repositories: Repositories) {
        guard let id = item?.grade.id else { return }

        do {
            try repositories.grades.delete(id: id)
            wasDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
