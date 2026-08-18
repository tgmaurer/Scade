#if os(macOS)
import AppKit
import SwiftUI
import Testing

/// Asks where in a frame a view's content actually ended up.
///
/// `ImageRenderer` draws SwiftUI content on transparency, so "is anything
/// drawn here" is "is any pixel in this band non-transparent". Reading pixels
/// is a blunt instrument and it's the only one available: a rendered image has
/// no view tree left to query, and a height assertion is structurally blind to
/// position — a bottom-aligned row and a top-aligned one are exactly as tall.
///
/// Shared by the tile tests, which all ask the same question of a different
/// view.
@MainActor
enum RenderedInk {
    /// Whether anything is drawn in the bottom `1/divisor` of the render.
    static func reachesBottom(
        of content: some View,
        width: Double,
        height: Double,
        divisor: Int = 8
    ) throws -> Bool {
        let renderer = ImageRenderer(content: content.frame(width: width, height: height))
        let image = try #require(renderer.cgImage)

        let pixelWidth = image.width
        let pixelHeight = image.height
        var pixels = [UInt8](repeating: 0, count: pixelWidth * pixelHeight * 4)

        let context = try #require(
            CGContext(
                data: &pixels,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: pixelWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: Double(pixelWidth), height: Double(pixelHeight))
        )

        let bandTop: Int = pixelHeight - pixelHeight / divisor

        for y in bandTop..<pixelHeight {
            for x in 0..<pixelWidth where pixels[(y * pixelWidth + x) * 4 + 3] > 0 {
                return true
            }
        }
        return false
    }
}
#endif
