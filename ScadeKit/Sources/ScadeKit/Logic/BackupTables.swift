import Foundation

/// The tables of a backup, as CSV: three that mirror the database, and one
/// that reads without them.
///
/// **The three normalised tables are the record.** The ids are kept, so they
/// re-join exactly as they sit in the database, and they are what a script
/// or a re-import wants.
///
/// **`overview` is for a person with a spreadsheet.** The ids that make the
/// three faithful are also what makes them unreadable: no column says which
/// education `educationId = 2` is. Excel can join them through Power Query,
/// Numbers has no join at all — only `VLOOKUP` written by hand, after
/// copying each file into one document, because Numbers opens every CSV as a
/// document of its own. Neither is something anyone does casually, and these
/// files exist to be read.
///
/// So the overview spells the parents out on every row. It is a left join,
/// not an inner one, which is what lets it replace nothing: an education
/// with no subjects and a subject with no grades each still get a row, with
/// the columns below them empty. That was the reason to have only normalised
/// tables, and it does not survive contact with a left join.
///
/// Every column is the stored value, not the displayed one — `weight` is the
/// multiplier the app calculates with, where `1.0` is the `100%` on screen.
/// The two average columns are the exception, and the only computed values
/// in any of these files: they come from `GradeCalculator`, the same one the
/// screens use.
public enum BackupTables {
    public static func educations(_ educations: [Education]) -> String {
        CSV.document(
            header: [
                "id", "name", "institution", "description", "semesters",
                "startDate", "endDate", "completed", "updatedAt",
            ],
            rows: educations.map { education in
                [
                    id(education.id),
                    education.name,
                    education.institution ?? "",
                    education.description ?? "",
                    String(education.semesters),
                    education.startDate.iso8601String,
                    education.endDate.iso8601String,
                    flag(education.completed),
                    CSV.timestamp(education.updatedAt),
                ]
            }
        )
    }

    public static func subjects(_ subjects: [Subject]) -> String {
        CSV.document(
            header: [
                "id", "educationId", "name", "description", "semester",
                "weight", "completed", "updatedAt",
            ],
            rows: subjects.map { subject in
                [
                    id(subject.id),
                    String(subject.educationId),
                    subject.name,
                    subject.description ?? "",
                    String(subject.semester),
                    CSV.number(subject.weight),
                    flag(subject.completed),
                    CSV.timestamp(subject.updatedAt),
                ]
            }
        )
    }

    public static func grades(_ grades: [Grade]) -> String {
        CSV.document(
            header: [
                "id", "subjectId", "value", "weight", "description",
                "date", "updatedAt",
            ],
            rows: grades.map { grade in
                [
                    id(grade.id),
                    String(grade.subjectId),
                    CSV.number(grade.value),
                    CSV.number(grade.weight),
                    grade.description ?? "",
                    grade.date.iso8601String,
                    CSV.timestamp(grade.updatedAt),
                ]
            }
        )
    }

    /// Every grade in the database, with the subject and education that
    /// place it spelled out on the same row.
    ///
    /// Rows come in the order the screens show them — educations newest
    /// first, subjects in the canonical §3.6 order, grades newest first —
    /// rather than sorted for the file. Anyone opening this in a spreadsheet
    /// will sort it their own way; matching the app means the two can be
    /// read side by side.
    public static func overview(_ summaries: [EducationSummary]) -> String {
        CSV.document(
            header: [
                "education", "institution", "educationAverage",
                "semester", "subject", "subjectWeight", "subjectAverage",
                "date", "grade", "gradeWeight", "gradeDescription",
            ],
            rows: summaries.flatMap(rows(for:))
        )
    }

    /// One education's rows: one per grade, or a single row carrying just the
    /// education when it has no subjects at all.
    private static func rows(for summary: EducationSummary) -> [[String]] {
        let education = [
            summary.education.name,
            summary.education.institution ?? "",
            optionalNumber(GradeCalculator.educationAverage(of: summary.subjects)),
        ]

        guard summary.subjects.isEmpty == false else {
            return [education + Array(repeating: "", count: 8)]
        }

        return summary.subjects.flatMap { entry in
            rows(for: entry).map { education + $0 }
        }
    }

    /// One subject's rows, minus the education columns: one per grade, or a
    /// single row carrying just the subject when it has none.
    private static func rows(for entry: SubjectGrades) -> [[String]] {
        let subject = [
            String(entry.subject.semester),
            entry.subject.name,
            CSV.number(entry.subject.weight),
            optionalNumber(GradeCalculator.subjectAverage(of: entry.grades)),
        ]

        guard entry.grades.isEmpty == false else {
            return [subject + Array(repeating: "", count: 4)]
        }

        return entry.grades.map { grade in
            subject + [
                grade.date.iso8601String,
                CSV.number(grade.value),
                CSV.number(grade.weight),
                grade.description ?? "",
            ]
        }
    }

    /// An average that isn't there is an empty cell, not a zero — the same
    /// distinction the screens draw with N/A.
    ///
    /// Two decimal places, through the same `valueStyle` the screens use, so
    /// the file agrees with what it is a backup of. This is the one place a
    /// backup rounds: `CSV.number` writes a stored value in full, and an
    /// average is not stored — writing it in full would put
    /// `4.666666666666667` in a cell of a file whose whole purpose is being
    /// read. The grades it was computed from are in the same row, and the
    /// database is in the same folder, so nothing is lost by it.
    ///
    /// `en_US_POSIX`, not the reader's locale: a decimal comma here would
    /// collide with the separator, and every other number in these files is
    /// written the same way.
    private static func optionalNumber(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(GradeFormatter.valueStyle.locale(Locale(identifier: "en_US_POSIX")))
    }

    /// A record fetched from the database always has one; the optional is
    /// there for records that haven't been inserted yet, which never reach a
    /// backup.
    private static func id(_ value: Int64?) -> String {
        value.map(String.init) ?? ""
    }

    /// Words rather than `1`/`0`: the file is meant to be read.
    private static func flag(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
