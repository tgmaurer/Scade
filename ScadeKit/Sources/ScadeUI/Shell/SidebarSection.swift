import SwiftUI

/// The top-level areas of the app (SPEC §4).
///
/// On macOS and iPad these are sidebar rows; `NavigationSplitView` collapses
/// them into a stack on iPhone by itself (§1).
enum SidebarSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case educations
    case subjects
    case grades
    case settings

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .educations: "Educations"
        case .subjects: "Subjects"
        case .grades: "Grades"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .educations: "graduationcap"
        case .subjects: "books.vertical"
        case .grades: "list.number"
        case .settings: "gearshape"
        }
    }
}
