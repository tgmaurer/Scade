import SwiftUI

/// The handful of measurements the app doesn't get from the system.
///
/// Deliberately short. SwiftUI's default spacing and padding adapt to Dynamic
/// Type and platform, so anything that can be left to the system is left to
/// the system; only values the system has no opinion about live here.
enum ScadeDesign {
    /// Gap between an inline icon and the text it qualifies — tighter than
    /// the default stack spacing, which is meant for separate elements.
    static let iconTextSpacing: Double = 4

    /// Corner radius for the small filled badges (averages, weights).
    static let badgeCornerRadius: Double = 6
}
