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
