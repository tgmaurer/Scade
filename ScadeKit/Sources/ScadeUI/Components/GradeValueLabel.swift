import ScadeKit
import SwiftUI

/// A grade value, marked as failing when it's below the passing mark.
///
/// SPEC §3.4 asks for red styling below 4. Colour alone isn't enough — when
/// "Differentiate Without Color" is on, the value also carries a warning
/// icon, so the distinction survives for anyone who can't rely on the red.
struct GradeValueLabel: View {
    let value: Double

    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var differentiateWithoutColor

    init(_ value: Double) {
        self.value = value
    }

    private var isFailing: Bool {
        GradingScale.isFailing(value)
    }

    private var accessibilityDescription: String {
        let formatted = value.formatted(GradeFormatter.valueStyle)
        return isFailing ? "\(formatted), failing" : formatted
    }

    var body: some View {
        // An `HStack` rather than a `Label`, deliberately: label styles adapt
        // to their context, and an icon-only context — a toolbar, say — would
        // hide the grade itself. The value must always be the visible part.
        HStack(spacing: ScadeDesign.iconTextSpacing) {
            if isFailing && differentiateWithoutColor {
                Image(systemName: "exclamationmark.triangle.fill")
            }

            Text(value, format: GradeFormatter.valueStyle)
        }
        .foregroundStyle(isFailing ? Color.red : Color.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

#Preview {
    VStack(alignment: .trailing) {
        GradeValueLabel(6.0)
        GradeValueLabel(4.0)
        GradeValueLabel(3.75)
        GradeValueLabel(1.0)
    }
    .padding()
}
