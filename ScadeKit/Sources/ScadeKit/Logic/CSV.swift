import Foundation

/// Writes RFC 4180 CSV.
///
/// The format a backup's tables are readable in — a spreadsheet, a script,
/// anything — as opposed to the `.sqlite` snapshot beside them, which is
/// what actually restores the app.
///
/// Fields are written exactly as they are. A description beginning `=` is a
/// formula to Excel and a description to everyone else, and mangling the
/// data to defend against one program's misreading of it would make the
/// export a worse record of what the app holds.
public enum CSV {
    /// `\r\n`, which RFC 4180 specifies and every spreadsheet reads. A bare
    /// `\n` works in most of them, and "most" is the wrong bar for the file
    /// that exists so the data is never trapped.
    public static let lineBreak = "\r\n"

    /// Excel reads a UTF-8 file as Latin-1 without this, turning every umlaut
    /// into mojibake on a double-click. Numbers and `utf-8-sig` in Python
    /// both skip it; a naive `split(",")` parser sees it on the first header
    /// name, which is the trade being made.
    public static let byteOrderMark = "\u{FEFF}"

    /// One field, quoted only where it has to be.
    public static func field(_ value: String) -> String {
        let needsQuoting = value.contains { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }
        guard needsQuoting else { return value }

        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    public static func row(_ fields: [String]) -> String {
        fields.map(field).joined(separator: ",")
    }

    /// A whole file: a header, its rows, and a trailing line break.
    public static func document(header: [String], rows: [[String]]) -> String {
        let lines = [row(header)] + rows.map(row)
        return byteOrderMark + lines.joined(separator: lineBreak) + lineBreak
    }

    /// A number with a `.` decimal separator whatever the machine's locale
    /// says — a weight written `0,625` in a Swiss locale is two columns to
    /// every reader of the file.
    public static func number(_ value: Double) -> String {
        String(value)
    }

    /// A timestamp as ISO 8601 in UTC, for the same reason. The format style
    /// rather than `ISO8601DateFormatter`, which is a class and can't be held
    /// in a shared constant under strict concurrency.
    public static func timestamp(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}
