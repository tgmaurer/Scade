import SwiftUI

extension View {
    /// Stops the macOS window being resized below the point where the
    /// dashboard stops working.
    ///
    /// A subject row puts a name, its grades and its average on one line. Past
    /// a certain narrowness those genuinely cannot coexist, and the honest
    /// answer is to refuse the window size rather than to design a layout for
    /// a window nobody uses.
    ///
    /// A no-op on iOS, where the app doesn't choose its own size.
    func windowSizeFloor() -> some View {
        #if os(macOS)
        frame(
            minWidth: ScadeDesign.minimumWindowWidth,
            minHeight: ScadeDesign.minimumWindowHeight
        )
        #else
        self
        #endif
    }
}
