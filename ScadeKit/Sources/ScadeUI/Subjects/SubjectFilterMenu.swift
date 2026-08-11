import ScadeKit
import SwiftUI

/// The filter controls for the subjects list (§3.5).
struct SubjectFilterMenu: View {
    @Binding var completion: CompletionFilter
    @Binding var institution: String?
    @Binding var semester: Int?
    let institutions: [String]
    let semesters: [Int]

    private var isFiltering: Bool {
        completion != .all || institution != nil || semester != nil
    }

    var body: some View {
        Menu {
            Picker("Status", selection: $completion) {
                ForEach(CompletionFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.inline)

            if semesters.isEmpty == false {
                Picker("Semester", selection: $semester) {
                    Text("All Semesters").tag(Int?.none)

                    ForEach(semesters, id: \.self) { value in
                        Text("Semester \(value.formatted(.number.grouping(.never)))")
                            .tag(Int?.some(value))
                    }
                }
                .pickerStyle(.inline)
            }

            if institutions.isEmpty == false {
                Picker("Institution", selection: $institution) {
                    Text("All Institutions").tag(String?.none)

                    ForEach(institutions, id: \.self) { name in
                        Text(name).tag(String?.some(name))
                    }
                }
                .pickerStyle(.inline)
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
