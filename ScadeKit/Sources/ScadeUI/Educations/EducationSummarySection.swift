import ScadeKit
import SwiftUI

/// The education's own details, above its subject list: the identity card,
/// and the description under a header of its own where there is one.
///
/// The content lives in `EducationDetailHeader`; this is the card plumbing
/// around it, kept separate so the header can be rendered and measured on its
/// own.
struct EducationSummarySection: View {
    let summary: EducationSummary
    let average: Double?

    private var details: String? {
        guard let details = summary.education.description, details.isEmpty == false else {
            return nil
        }
        return details
    }

    var body: some View {
        Section {
            EducationDetailHeader(summary: summary, average: average)
                // Figures, not a way through to anything — nothing on this
                // card is clickable, so nothing on it should light up (§2.8).
                .cardRow(.only, highlightsOnHover: false)
        }
        .cardSection()

        if let details {
            // A card of its own rather than a last paragraph of the one
            // above. A description runs to 2500 characters, which would
            // swamp the identity it was meant to qualify.
            Section {
                Text(details)
                    .cardRow(.only, highlightsOnHover: false)
            } header: {
                Text("Description")
                    .font(ScadeDesign.rowSecondary)
                    .bold()
                    .textCase(nil)
                    .cardSectionHeader()
            }
            .cardSection()
        }
    }
}

#Preview {
    List {
        EducationSummarySection(
            summary: EducationSummary(education: PreviewData.education(), subjects: []),
            average: 5.25
        )
    }
    .groupedListStyle()
}
