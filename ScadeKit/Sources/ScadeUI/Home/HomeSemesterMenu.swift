import SwiftUI

/// The dashboard's semester filter, bounded by the education's own semester
/// count (SPEC §4).
struct HomeSemesterMenu: View {
    @Binding var semester: Int?
    let semesters: [Int]

    var body: some View {
        Menu {
            // Inline, so the semesters are in the menu rather than behind a
            // "Semester" submenu inside it. See `HomeEducationMenu`.
            Picker("Semester", selection: $semester) {
                Text("All Semesters").tag(Int?.none)

                ForEach(semesters, id: \.self) { value in
                    Text("Semester \(value.formatted(.number.grouping(.never)))")
                        .tag(Int?.some(value))
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label(
                "Semester",
                systemImage: semester == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .help("Show one semester of this education")
    }
}
