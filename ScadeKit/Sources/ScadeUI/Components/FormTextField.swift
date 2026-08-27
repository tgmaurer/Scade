import SwiftUI

/// One labelled line of free text in a form.
///
/// It exists for a macOS bug. A grouped `Form` there lays a labelled field
/// out as label-left, field-right — and anchors the text to the field's
/// *trailing* edge, so **a typed space never appears**: a trailing space has
/// no mark of its own and the anchor doesn't move, leaving the row
/// pixel-for-pixel identical before and after the keystroke. The space reads
/// as dropped, and then the next character lands and the whole string jumps
/// left by two. Typing "Modul 4" shows `Modul`, `Modul`, `Modul 4`.
///
/// `.multilineTextAlignment(.leading)` on the field alone does nothing —
/// SwiftUI's own label layout wins, so the label has to go. With it hidden
/// and a label column in front instead, the alignment takes effect *and* the
/// text starts just after the word naming it: `LabeledContent` splits the row
/// roughly in half, which left a name beginning in the middle of the sheet
/// with a stretch of nothing in front of it.
///
/// The numeric fields keep the trailing alignment, and `IntegerField` keeps
/// `LabeledContent` with it: a column of figures lining up on the right is
/// the point there, and nobody types a space into one.
///
/// iOS is unaffected — a form field's text already reads from the left, and
/// the bare `TextField` is what belongs on a phone, where a label column
/// would eat the width the value needs.
///
/// The multi-line description fields need none of this: `.labelsHidden()`
/// leaves them full-width, and a full-width field is leading-aligned already
/// (measured).
struct FormTextField: View {
    let title: LocalizedStringKey
    @Binding var text: String

    /// Applied to the field itself rather than to this view: on macOS the
    /// field sits inside a row of its own, and an identifier on the container
    /// is not the one automation types into.
    var identifier: String?

    var body: some View {
        #if os(macOS)
        HStack(spacing: ScadeDesign.rowSpacing) {
            Text(title)
                // A column, so the fields below each other start in the same
                // place. Wide enough for the longest label the app puts in
                // front of free text.
                .frame(width: ScadeDesign.formLabelWidth, alignment: .leading)

            field
                .labelsHidden()
                .multilineTextAlignment(.leading)
        }
        #else
        field
        #endif
    }

    private var field: some View {
        TextField(title, text: $text)
            .accessibilityIdentifier(identifier ?? "")
    }
}

#Preview {
    @Previewable @State var name = ""

    Form {
        FormTextField(title: "Name", text: $name)
    }
    .formStyle(.grouped)
}
