#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import ScadeKit
@testable import ScadeUI

/// The education tile is the same height whatever is written in it.
///
/// A grid row is as tall as the tallest tile in it, so a tile that grows a
/// line doesn't only look wrong itself — it leaves dead space under every
/// other education beside it. That's what a wrapping institution did, and
/// it's invisible to every flow test: the app built, launched, and drew all
/// the right words.
///
/// Measured with `ImageRenderer`, which gives a real layout pass without a
/// window. It measures the row alone; the grid around it is a `LazyVGrid` in
/// a `ScrollView` and renders no more headlessly than a `List` does — see
/// `CardGridTests` for the part of the grid that *is* reachable.
@MainActor
struct EducationRowLayoutTests {
    /// Long enough to overflow a tile at any column count — this is a real
    /// institution name, and the one in the screenshot that wrapped.
    private let longInstitution = "gibb, Gewerblich Industrielle Berufsfachschule Bern"

    /// The narrowest a tile is ever laid out at, less its own padding: the
    /// minimum card width is the floor the grid holds to, so a row that fits
    /// here fits everywhere.
    private let narrowest = ScadeDesign.minimumCardWidth - 2 * ScadeDesign.cardTilePadding

    private func row(institution: String?) -> EducationRow {
        var education = Education(
            name: "Informatiker EFZ",
            description: nil,
            semesters: 8,
            startDate: .today(),
            endDate: .today().adding(years: 4),
            institution: institution
        )
        education.id = 1

        return EducationRow(EducationSummary(education: education, subjects: []))
    }

    private func height(institution: String?, width: Double) throws -> Double {
        let renderer = ImageRenderer(
            content: EducationRowView(row: row(institution: institution)).frame(width: width)
        )
        return try #require(renderer.nsImage).size.height
    }

    /// The fix, stated directly: however long the institution, the tile is
    /// the height of the one beside it.
    @Test(arguments: [300.0, 420.0, 600.0])
    func aLongInstitutionDoesNotMakeTheRowTaller(width: Double) throws {
        let long = try height(institution: longInstitution, width: width - 2 * ScadeDesign.cardTilePadding)
        let short = try height(institution: "ETH", width: width - 2 * ScadeDesign.cardTilePadding)

        #expect(long == short)
    }

    /// And an education with no institution at all matches too — that row
    /// takes a different branch, so it could drift on its own.
    @Test func anEducationWithNoInstitutionIsTheSameHeight() throws {
        let none = try height(institution: nil, width: narrowest)
        let some = try height(institution: "ETH", width: narrowest)

        #expect(none == some)
    }

    /// An empty string is not an institution, and must not render as one with
    /// a separator hanging off it.
    @Test func anEmptyInstitutionIsTreatedAsNone() throws {
        let empty = try height(institution: "", width: narrowest)
        let none = try height(institution: nil, width: narrowest)

        #expect(empty == none)
    }

    // MARK: - The name

    private func row(name: String) -> EducationRow {
        var education = Education(
            name: name,
            description: nil,
            semesters: 8,
            startDate: .today(),
            endDate: .today().adding(years: 4),
            institution: "ETH"
        )
        education.id = 1

        return EducationRow(EducationSummary(education: education, subjects: []))
    }

    private func height(name: String, width: Double) throws -> Double {
        let renderer = ImageRenderer(
            content: EducationRowView(row: row(name: name)).frame(width: width)
        )
        return try #require(renderer.nsImage).size.height
    }

    /// The name wraps once and then stops.
    ///
    /// Unlike the institution it isn't held to one line — it's what identifies
    /// the education, and nothing else on the tile repeats it. But it is
    /// bounded: `ValidationLimits.maximumNameLength` is 255 characters, which
    /// is some fifteen lines at tile width, and a grid row is as tall as its
    /// tallest tile.
    @Test func aNameLongerThanTwoLinesIsNoTallerThanTwoLines() throws {
        let twoLines = try height(name: String(repeating: "Wide ", count: 12), width: narrowest)
        let far = try height(
            name: String(repeating: "a", count: ValidationLimits.maximumNameLength),
            width: narrowest
        )

        #expect(far == twoLines)
    }

    /// A short name still gets one line, so the bound isn't a floor.
    @Test func aShortNameStaysOneLine() throws {
        let short = try height(name: "EFZ", width: narrowest)
        let twoLines = try height(name: String(repeating: "Wide ", count: 12), width: narrowest)

        #expect(short < twoLines)
    }

    // MARK: - Bottom alignment

    /// Whether anything is drawn in the bottom eighth of the rendered row.
    ///
    /// `ImageRenderer` draws SwiftUI content on transparency, so "is there
    /// ink here" is just "is any pixel in this band non-transparent". Reading
    /// pixels is a blunt instrument, but it's the only way to ask where in a
    /// frame the content ended up — a rendered image has no view tree left to
    /// query, and the height assertions above can't see a thing about
    /// position.
    private func bottomBandIsInked(name: String, width: Double, height: Double) throws -> Bool {
        let renderer = ImageRenderer(
            content: EducationRowView(row: row(name: name)).frame(width: width, height: height)
        )
        let image = try #require(renderer.cgImage)

        let bandTop = image.height - image.height / 8
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)

        let context = try #require(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        return (bandTop..<image.height).contains { y in
            (0..<image.width).contains { x in
                pixels[(y * image.width + x) * 4 + 3] > 0
            }
        }
    }

    /// Given more height than it needs, the row spreads rather than sitting at
    /// the top of it.
    ///
    /// This is what stops a tall tile leaving dead space under the short ones
    /// beside it: every tile in a grid row is as tall as the tallest, so the
    /// counts and status have to reach the bottom of that height rather than
    /// trailing off wherever their own text ran out.
    @Test func theRowReachesTheBottomOfATallerFrameThanItNeeds() throws {
        let natural = try height(name: "EFZ", width: narrowest)

        #expect(try bottomBandIsInked(name: "EFZ", width: narrowest, height: natural * 2))
    }
}
#endif
