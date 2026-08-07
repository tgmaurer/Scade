import ScadeKit
import SwiftUI

/// The name column of a dashboard row, and the only part of it that navigates.
///
/// How much of the column the button claims is the one thing that genuinely
/// differs by input device:
///
/// - **A pointer can hit the text itself.** So on macOS the button hugs the
///   name and the rest of the column stays inert. The alternative — the button
///   filling the column — is the bug this screen just had: 160pt of empty
///   space that navigated when clicked.
/// - **A finger can't.** On a phone the button takes the whole column and a
///   target height that clears the 44pt guideline. There are no grade chips
///   competing for the row there (§2.3 drops them in a compact width), so
///   nothing is lost by the name claiming the space.
///
/// Either way the width belongs to *this* view, never to the button inside it.
struct HomeSubjectName: View {
    let subject: Subject

    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            SubjectButton(subject: subject)
            Spacer(minLength: 0)
        }
        .frame(minWidth: ScadeDesign.subjectColumnWidth, alignment: .leading)
        #else
        SubjectButton(subject: subject)
            .frame(
                minWidth: ScadeDesign.subjectColumnWidth,
                minHeight: ScadeDesign.touchTargetHeight,
                alignment: .leading
            )
        #endif
    }
}

#Preview {
    HomeSubjectName(subject: PreviewData.homeSubject().subject)
        .padding()
}
