import SwiftUI

/// A form's paragraph of free text — a description, and nothing else so far.
///
/// It exists because Return has to mean *new line* here, and in a
/// `TextField` it doesn't. A sheet's Save is its default button, so Return
/// anywhere inside the sheet fires it: the form tries to save, and on macOS
/// the field's uncommitted text is discarded on the way, so a paragraph typed
/// before the keystroke is silently lost. `axis: .vertical` doesn't change
/// that — it wraps and grows, but the key still belongs to the button.
///
/// A `TextEditor` is a real text view and takes the key itself, so it never
/// reaches Save. The cost is that it doesn't grow with its content the way
/// the wrapping field did: it gets a fixed height and scrolls inside. For a
/// field capped at 2500 characters that's the better half of the trade —
/// a form that grew to twenty lines as you typed would push Save off the
/// bottom of the sheet.
///
/// iOS keeps the wrapping `TextField`: the Return key on a software keyboard
/// inserts a line break there rather than submitting, so the problem this
/// solves doesn't exist on a phone, and the field's growth is worth keeping.
struct FormTextEditor: View {
    let title: LocalizedStringKey
    @Binding var text: String

    var identifier: String?

    var body: some View {
        #if os(macOS)
        TextEditor(text: $text)
            .font(.body)
            // Otherwise the editor paints its own square slab of
            // `textBackgroundColor` across the form row's rounded fill.
            .scrollContentBackground(.hidden)
            // A text view insets its own text a few points from its edges,
            // which would start the paragraph past the labels above it.
            // Pulled back so the description begins where "Name" does.
            .padding(.leading, -ScadeDesign.formEditorTextInset)
            .frame(height: ScadeDesign.formEditorHeight)
            .accessibilityIdentifier(identifier ?? "")
        #else
        TextField(title, text: $text, axis: .vertical)
            .lineLimit(3...)
            .labelsHidden()
            .accessibilityIdentifier(identifier ?? "")
        #endif
    }
}

#Preview {
    @Previewable @State var details = ""

    Form {
        Section("Description") {
            FormTextEditor(title: "Description", text: $details)
        }
    }
    .formStyle(.grouped)
}
