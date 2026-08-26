import AppKit
import CoreGraphics

let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

// ── Geometry ────────────────────────────────────────────────────────────────
let cx: CGFloat = 512
let bcy: CGFloat = 462, bw: CGFloat = 392, bh: CGFloat = 200   // board (rhombus)
let boardR: CGFloat = 46                                        // corner radius
let sq: CGFloat = 330, sqTop: CGFloat = 432, crownR: CGFloat = 46

// ── Colour ──────────────────────────────────────────────────────────────────
let board = CGColor(srgbRed: 0.392, green: 0.380, blue: 0.910, alpha: 1)   // #6461E8
let crown = CGColor(srgbRed: 0.259, green: 0.239, blue: 0.733, alpha: 1)   // #423DBB

/// A polygon with every vertex rounded to `r`.
func roundedPolygon(_ pts: [CGPoint], _ r: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let mid = CGPoint(x: (pts[0].x + pts[1].x) / 2, y: (pts[0].y + pts[1].y) / 2)
    p.move(to: mid)
    for i in 0..<pts.count {
        let corner = pts[(i + 1) % pts.count]
        let next = pts[(i + 2) % pts.count]
        p.addArc(tangent1End: corner, tangent2End: next, radius: r)
    }
    p.closeSubpath()
    return p
}

func boardPath() -> CGPath {
    roundedPolygon([CGPoint(x: cx, y: bcy - bh), CGPoint(x: cx + bw, y: bcy),
                    CGPoint(x: cx, y: bcy + bh), CGPoint(x: cx - bw, y: bcy)], boardR)
}

func crownPath() -> CGPath {
    CGPath(roundedRect: CGRect(x: cx - sq / 2, y: sqTop, width: sq, height: sq),
           cornerWidth: crownR, cornerHeight: crownR, transform: nil)
}

func newContext() -> CGContext {
    let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: S); ctx.scaleBy(x: 1, y: -1)   // top-left origin, like the SVG
    return ctx
}

func write(_ ctx: CGContext, _ url: URL) {
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    rep.size = NSSize(width: S, height: S)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

func backdrop(_ ctx: CGContext, _ color: CGColor?) {
    guard let color else { return }
    ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: S, height: S),
                       cornerWidth: 228, cornerHeight: 228, transform: nil))
    ctx.setFillColor(color); ctx.fillPath()
}

/// gap > 0 cuts a clear band along the board's edge, so the two pieces read as
/// separate fragments rather than one silhouette.
func render(gap: CGFloat, background: CGColor?, to url: URL) {
    let ctx = newContext()
    backdrop(ctx, background)
    ctx.addPath(crownPath()); ctx.setFillColor(crown); ctx.fillPath()
    if gap > 0 {
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        ctx.addPath(boardPath())
        ctx.setLineWidth(gap * 2); ctx.setLineJoin(.round)
        ctx.strokePath()
        ctx.restoreGState()
    }
    ctx.addPath(boardPath()); ctx.setFillColor(board); ctx.fillPath()
    write(ctx, url)
}

/// One piece on its own, centred in the canvas.
func renderFragment(_ path: CGPath, _ color: CGColor, to url: URL) {
    let ctx = newContext()
    let b = path.boundingBox
    ctx.translateBy(x: (S - b.width) / 2 - b.minX, y: (S - b.height) / 2 - b.minY)
    ctx.addPath(path); ctx.setFillColor(color); ctx.fillPath()
    write(ctx, url)
}

/// Walks a CGPath into SVG path data, so the vector source can't drift from the PNGs.
func svgPathData(_ path: CGPath) -> String {
    var d = ""
    func f(_ v: CGFloat) -> String { String(format: "%.2f", v) }
    path.applyWithBlock { el in
        let pts = el.pointee.points
        switch el.pointee.type {
        case .moveToPoint:    d += "M \(f(pts[0].x)) \(f(pts[0].y)) "
        case .addLineToPoint: d += "L \(f(pts[0].x)) \(f(pts[0].y)) "
        case .addQuadCurveToPoint:
            d += "Q \(f(pts[0].x)) \(f(pts[0].y)) \(f(pts[1].x)) \(f(pts[1].y)) "
        case .addCurveToPoint:
            d += "C \(f(pts[0].x)) \(f(pts[0].y)) \(f(pts[1].x)) \(f(pts[1].y)) \(f(pts[2].x)) \(f(pts[2].y)) "
        case .closeSubpath:   d += "Z "
        @unknown default:     break
        }
    }
    return d.trimmingCharacters(in: .whitespaces)
}

func writeSVG(to url: URL) {
    let svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
      <title>Scade — mortarboard mark</title>
      <!-- crown: solid, deeper indigo, sitting behind the board -->
      <path d="\(svgPathData(crownPath()))" fill="#423DBB"/>
      <!-- board: the rhombus, lighter indigo -->
      <path d="\(svgPathData(boardPath()))" fill="#6461E8"/>
    </svg>
    """
    try! svg.write(to: url, atomically: true, encoding: .utf8)
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
render(gap: 0,  background: nil, to: out.appendingPathComponent("scade-icon-mark-1024.png"))
render(gap: 14, background: nil, to: out.appendingPathComponent("scade-icon-split-1024.png"))
render(gap: 0,  background: CGColor(srgbRed: 0.976, green: 0.976, blue: 0.988, alpha: 1),
       to: out.appendingPathComponent("scade-icon-light-1024.png"))
render(gap: 0,  background: CGColor(srgbRed: 0.106, green: 0.102, blue: 0.145, alpha: 1),
       to: out.appendingPathComponent("scade-icon-dark-1024.png"))
renderFragment(boardPath(), board, to: out.appendingPathComponent("fragment-board-1024.png"))
renderFragment(crownPath(), crown, to: out.appendingPathComponent("fragment-crown-1024.png"))
print("ok")
writeSVG(to: out.appendingPathComponent("scade-icon.svg"))
