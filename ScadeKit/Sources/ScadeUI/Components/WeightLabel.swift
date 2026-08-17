import ScadeKit
import SwiftUI

/// A weight multiplier, shown as a percentage.
///
/// Storage keeps the raw multiplier; `125%` simply reads better than `1.25`
/// (§3.3).
struct WeightLabel: View {
    let multiplier: Double

    init(_ multiplier: Double) {
        self.multiplier = multiplier
    }

    /// Whether a weight is worth printing where space is scarce.
    ///
    /// A weight of 1 is the absence of weighting, and printing "100%" on every
    /// row of a list makes the rows that *are* weighted harder to find — the
    /// opposite of what showing it is for. Somewhere with room to be complete,
    /// like a detail screen, still shows it; this is the rule for rows and
    /// chips, which is why it's a question to ask rather than something baked
    /// into the label itself.
    static func isMeaningful(_ multiplier: Double) -> Bool {
        multiplier != 1.0
    }

    var body: some View {
        Text(multiplier, format: GradeFormatter.weightStyle)
            .accessibilityLabel("Weight \(multiplier.formatted(GradeFormatter.weightStyle))")
    }
}

#Preview {
    VStack(alignment: .trailing) {
        WeightLabel(1.0)
        WeightLabel(1.25)
        WeightLabel(0.625)
        WeightLabel(0.125)
    }
    .padding()
}
