import Foundation

/// The three tables of a backup, as CSV.
///
/// One file per table rather than one flat joined file: the ids are kept, so
/// the three re-join exactly as they sit in the database, and a subject with
/// no grades or an education with no subjects still appears. A single
/// denormalised sheet reads more easily and quietly drops both.
///
/// Every column is the stored value, not the displayed one — `weight` is the
/// multiplier the app calculates with, where `1.0` is the `100%` on screen.
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
