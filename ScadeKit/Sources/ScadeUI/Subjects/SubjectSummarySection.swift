import ScadeKit
import SwiftUI

/// The subject's own details, above its grade list: the identity card, and
/// the description under a header of its own where there is one.
///
/// The content lives in `SubjectDetailHeader`; this is the card plumbing
/// around it, kept separate so the header can be rendered and measured on its
/// own. Mirrors `EducationSummarySection` exactly.
struct SubjectSummarySection: View {
    let summary: SubjectSummary
    let average: Double?

    private var details: String? {
        guard let details = summary.subject.description, details.isEmpty == false else {
            return nil
        }
        return details
    }

    var body: some View {
        DetailSection {
            DetailSectionText {
                SubjectDetailHeader(summary: summary, average: average)
            }
        }

        if let details {
            DetailSection(title: "Description") {
                DetailSectionText {
                    Text(details)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: ScadeDesign.contentMargin) {
            SubjectSummarySection(
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
        .padding(ScadeDesign.contentMargin)
    }
}
