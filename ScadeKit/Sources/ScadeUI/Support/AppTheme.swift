import SwiftUI

/// The appearance setting from SPEC §4.
public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` hands the decision back to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
