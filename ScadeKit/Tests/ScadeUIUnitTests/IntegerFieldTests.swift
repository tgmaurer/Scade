import Testing
@testable import ScadeUI

/// What a whole-number field will let you type.
///
/// `TextField(value:format: .number)` accepted anything and simply failed to
/// parse it, so "abc" sat in a semester field looking like an answer until the
/// form was saved and reverted it. The rule is now that invalid characters
/// never arrive at all, which is only worth having if it's exact.
struct IntegerFieldTests {
    @Test func keepsDigits() {
        #expect(IntegerField.digits(in: "2026") == "2026")
    }

    @Test func dropsLetters() {
        #expect(IntegerField.digits(in: "a1b2c3") == "123")
    }

    @Test func dropsSpacesAndPunctuation() {
        #expect(IntegerField.digits(in: " 1 000, ") == "1000")
    }

    /// A whole number has no fractional part and nothing the app stores as one
    /// can be negative (SPEC §3), so neither mark gets in.
    @Test func dropsTheSignAndTheDecimalPoint() {
        #expect(IntegerField.digits(in: "-4.5") == "45")
    }

    /// `Character.isNumber` is true of these and `Int(_:)` parses none of
    /// them, so admitting them would leave characters in the field that
    /// silently mean zero.
    @Test(arguments: ["½", "٧", "Ⅷ", "㊈"])
    func dropsNumbersThatArentAsciiDigits(character: String) {
        #expect(IntegerField.digits(in: character).isEmpty)
    }

    @Test func nothingTypedIsNothingKept() {
        #expect(IntegerField.digits(in: "").isEmpty)
    }
}
