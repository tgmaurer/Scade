import SwiftUI

extension View {
    /// Asks for a numeric keyboard where there is one.
    ///
    /// `keyboardType` is iOS-only, so the platform check lives here instead
    /// of in every form that takes a number.
    func numberPadKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }

    /// The same, for values that can have a fractional part — weights and
    /// grade values both can.
    func decimalPadKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
