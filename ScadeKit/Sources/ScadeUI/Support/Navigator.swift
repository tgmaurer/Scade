import SwiftUI

/// Pushes a value onto the enclosing `SectionStack`'s navigation path.
///
/// **Why not `NavigationLink`.** macOS `List` gives a row that contains one a
/// presentation of its own — full width, its own styling, its own idea of
/// where the label goes. That's right for a row which *is* a link, and ruinous
/// for a row that merely contains some: on the dashboard the subject name and
/// every grade chip each claimed a full-width line, the chips lost their
/// backgrounds, the average vanished, and none of them navigated. One link per
/// row survives it; several do not.
///
/// So those controls are `Button`s, which a `List` leaves alone, and this is
/// how a button reaches the stack it sits in. The three flat lists still use
/// `NavigationLink` — there the whole row is the link, which is the case
/// `List` handles well.
///
/// Destinations are still registered with `navigationDestination(for:)` and
/// still matched by type, so nothing about how a screen is reached changes.
struct Navigator {
    private let push: (any Hashable) -> Void

    init(push: @escaping (any Hashable) -> Void) {
        self.push = push
    }

    /// Navigates to whichever screen is registered for this value's type.
    func callAsFunction(_ value: some Hashable) {
        push(value)
    }
}

extension EnvironmentValues {
    /// Does nothing by default, so a row still previews outside a stack.
    @Entry var navigate = Navigator { _ in }
}
