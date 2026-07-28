import ScadeKit
import SwiftUI

/// A computed average, or "N/A" when there's nothing to average yet.
///
/// Takes the `Double?` that `GradeCalculator` returns rather than a plain
/// `Double`, so the "no grades yet" case can't be confused with a real value
/// — which is the whole point of dropping the old app's `0` sentinel (§3.2).
struct AverageLabel: View {
    let average: Double?

    init(_ average: Double?) {
        self.average = average
    }

    var body: some View {
        if let average {
            // Reuses the grade styling, so an average below 4 reads as
            // failing exactly like a grade does.
            GradeValueLabel(average)
        } else {
            Text(GradeFormatter.noDataPlaceholder)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        AverageLabel(5.25)
        AverageLabel(3.5)
        AverageLabel(nil)
    }
    .padding()
}
