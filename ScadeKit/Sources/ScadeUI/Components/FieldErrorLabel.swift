import SwiftUI

/// The inline explanation under a form field that failed validation.
///
/// SPEC §3.4 chose visible field errors over the old app's
/// silent-clamp-and-toast. The icon carries the meaning alongside the red, so
/// it still reads as an error without relying on colour.
struct FieldErrorLabel: View {
    let message: String?

    init(_ message: String?) {
        self.message = message
    }

    var body: some View {
        if let message {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .accessibilityIdentifier(AccessibilityID.Form.error)
        }
    }
}

#Preview {
    Form {
        TextField("Name", text: .constant(""))
        FieldErrorLabel("Enter a name.")
    }
}
