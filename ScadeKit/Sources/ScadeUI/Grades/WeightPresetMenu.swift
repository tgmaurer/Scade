import ScadeKit
import SwiftUI

/// Quick-picks for the common weights, beside the free numeric field.
struct WeightPresetMenu: View {
    @Binding var percent: Double

    var body: some View {
        Menu("Presets", systemImage: "list.bullet") {
            ForEach(WeightPreset.percentages, id: \.self) { preset in
                Button {
                    percent = preset
                } label: {
                    Text((preset / 100).formatted(GradeFormatter.weightStyle))
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var percent = 100.0

    Form {
        LabeledContent("Weight") {
            WeightPresetMenu(percent: $percent)
        }
    }
}
