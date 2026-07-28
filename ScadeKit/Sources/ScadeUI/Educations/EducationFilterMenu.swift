import ScadeKit
import SwiftUI

/// The filter controls for the educations list.
///
/// A control of its own rather than syntax typed into the search field —
/// §3.5 dropped the old app's `(ip)`/`(c)` suffixes precisely because the
/// only way to find them was to already know they existed.
struct EducationFilterMenu: View {
    @Binding var completion: CompletionFilter
    @Binding var institution: String?
    let institutions: [String]

    private var isFiltering: Bool {
        completion != .all || institution != nil
    }

    var body: some View {
        Menu {
            Picker("Status", selection: $completion) {
                ForEach(CompletionFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }

            if institutions.isEmpty == false {
                Picker("Institution", selection: $institution) {
                    Text("All Institutions").tag(String?.none)

                    ForEach(institutions, id: \.self) { name in
                        Text(name).tag(String?.some(name))
                    }
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: isFiltering
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
    }
}

#Preview {
    @Previewable @State var completion: CompletionFilter = .all
    @Previewable @State var institution: String?

    NavigationStack {
        Text("Filtered content")
            .toolbar {
                ToolbarItem {
                    EducationFilterMenu(
                        completion: $completion,
                        institution: $institution,
                        institutions: ["ETH Zürich", "Universität Basel"]
                    )
                }
            }
    }
}
