import SwiftUI

/// Numeric entry for a weight, in percent.
///
/// Storage keeps a multiplier (§3.3); the form takes the percentage because
/// that's the number people actually think in — "half weight" is 50, not 0.5.
struct WeightField: View {
    let title: LocalizedStringKey
    @Binding var percent: Double

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: ScadeDesign.iconTextSpacing) {
                TextField(title, value: $percent, format: .number)
                    .decimalPadKeyboard()
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()

                Text(verbatim: "%")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var percent = 100.0

    Form {
        WeightField(title: "Weight", percent: $percent)
    }
}
