import ScadeKit
import SwiftUI

/// The subject's own details, above its grade list: the identity card, and
/// the description under a header of its own where there is one.
///
/// The content lives in `SubjectDetailHeader`; this is the card plumbing
/// around it, kept separate so the header can be rendered and measured on its
/// own. Mirrors `educationSummarySection` exactly.
///
/// A function rather than a `View`, for the reason `DetailSection` is one:
/// `DetailScroll` pins section headers, and a `LazyVStack` pins only a
/// `Section` it can see. Sections wrapped in a view of their own are
/// invisible to it, and this held two of them.
@ViewBuilder
func subjectSummarySection(summary: SubjectSummary, average: Double?) -> some View {
    DetailSection {
        DetailSectionText {
            SubjectDetailHeader(summary: summary, average: average)
        }
    }

    if let details = summary.subject.description, details.isEmpty == false {
        // A card of its own rather than a last paragraph of the one above. A
        // description runs to 2500 characters, which would swamp the identity
        // it was meant to qualify.
        DetailSection(title: "Description") {
            DetailSectionText {
                Text(details)
                    // The longest free text the app holds, and the one most
                    // likely to be wanted elsewhere.
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    DetailScroll {
        subjectSummarySection(
            summary: SubjectSummary(
                subject: Subject(
                    educationId: 1,
                    name: "Analysis",
                    description: "Differential- und Integralrechnung.",
                    semester: 4
                ),
                education: PreviewData.education(),
                grades: []
            ),
            average: nil
        )
    }
}
