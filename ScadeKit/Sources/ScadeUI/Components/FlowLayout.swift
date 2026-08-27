import SwiftUI

/// Lays subviews out left to right, wrapping to a new line when the next one
/// doesn't fit.
///
/// `HStack` would push everything onto one line and clip; a `LazyVGrid` would
/// force equal-width columns, which looks wrong for items whose width is their
/// content. This is the layout for a run of chips of varying width.
///
/// Written against the `Layout` protocol rather than `GeometryReader`, so it
/// participates in the layout pass properly instead of reading a size back
/// from it.
struct FlowLayout: Layout {
    var spacing: Double = ScadeDesign.iconTextSpacing

    /// One laid-out line: which subviews are on it, and how tall it is.
    private struct Line {
        var indices: [Int] = []
        var height: Double = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let available = proposal.replacingUnspecifiedDimensions().width
        let lines = lines(of: subviews, within: available)

        let height =
            lines.reduce(0) { $0 + $1.height }
            + Double(max(0, lines.count - 1)) * spacing

        // The width actually used, not the width offered. Returning the
        // proposal would claim the whole row and leave neighbouring views —
        // the trailing average — nothing to sit in, so they'd overlap.
        let used = lines.map { lineWidth(of: $0, in: subviews) }.max() ?? 0

        return CGSize(width: min(used, available), height: height)
    }

    private func lineWidth(of line: Line, in subviews: Subviews) -> Double {
        let content = line.indices.reduce(0) { $0 + subviews[$1].sizeThatFits(.unspecified).width }
        return content + Double(max(0, line.indices.count - 1)) * spacing
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var y = bounds.minY

        for line in lines(of: subviews, within: bounds.width) {
            var x = bounds.minX

            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                // Centred on the line, not hung from its top. A line holds
                // items of different heights — a chip is taller than a bare
                // line of text — and topLeading left the shorter ones riding
                // high next to their neighbours.
                subviews[index].place(
                    at: CGPoint(x: x, y: y + line.height / 2),
                    anchor: .leading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }

            y += line.height + spacing
        }
    }

    /// Greedy line-breaking: keep adding to the current line until one doesn't
    /// fit. The first item on a line is always placed even if it's too wide,
    /// since starting a new line wouldn't help it.
    private func lines(of subviews: Subviews, within width: Double) -> [Line] {
        var lines: [Line] = []
        var current = Line()
        var x: Double = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needsBreak = current.indices.isEmpty == false && x + size.width > width

            if needsBreak {
                lines.append(current)
                current = Line()
                x = 0
            }

            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }

        if current.indices.isEmpty == false {
            lines.append(current)
        }

        return lines
    }
}
