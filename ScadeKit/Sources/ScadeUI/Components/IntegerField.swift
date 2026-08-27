import SwiftUI

/// Numeric entry for a whole number, which is the only thing it will accept.
///
/// `TextField(value:format: .number)` lets anything be typed and simply fails
/// to parse it, so "abc" sits in a semester field looking like an answer until
/// the form is saved and reverts it. Here the text is the state and non-digits
/// never reach it: they're dropped as they arrive, so there is no invalid
/// state to explain.
///
/// Trailing-aligned, like every other number in a form — that's the point of
/// them lining up, and it's why `FormTextField`'s leading alignment doesn't
/// apply. Nobody types a space into a semester.
///
/// Signed values would need the minus back; nothing the app stores as a whole
/// number can be negative (§3), so it isn't allowed in.
struct IntegerField: View {
    let title: LocalizedStringKey
    @Binding var value: Int

    var identifier: String?

    /// The text is the state, and `value` follows it. Deriving the text from
    /// the number instead would re-render "0" over an empty field the moment
    /// it was cleared, which makes the field impossible to retype.
    @State private var text = ""

    var body: some View {
        LabeledContent(title) {
            TextField(title, text: $text)
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .numberPadKeyboard()
                .accessibilityIdentifier(identifier ?? "")
        }
        .onAppear { text = String(value) }
        .onChange(of: text) { _, typed in
            let digits = Self.digits(in: typed)
            if digits != typed { text = digits }

            // An empty field is zero, not "unchanged": validation has
            // something to complain about either way, and leaving the last
            // number behind would save a value nobody can see.
            value = Int(digits) ?? 0
        }
        .onChange(of: value) { _, updated in
            // Only when something else moved it — a form that pre-fills the
            // field, or a value clamped elsewhere.
            if Int(text) != updated {
                text = String(updated)
            }
        }
    }

    /// The digits in what was typed, and nothing else.
    ///
    /// `nonisolated` because a `View` is main-actor isolated and this is pure
    /// text: without it the tests trap on the actor assumption rather than
    /// running.
    ///
    /// ASCII only. `Character.isNumber` is also true of "½" and of every
    /// other script's digits, none of which `Int(_:)` will parse — so
    /// admitting them would put characters in the field that silently mean
    /// zero.
    nonisolated static func digits(in text: String) -> String {
        String(text.filter { $0.isASCII && $0.isNumber })
    }
}

#Preview {
    @Previewable @State var semester = 3

    Form {
        IntegerField(title: "Semester", value: $semester)
        LabeledContent("Value", value: String(semester))
    }
    .formStyle(.grouped)
}
