import AppKit

func render(_ size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let k = CGFloat(size) / 1024
    ctx.scaleBy(x: k, y: k)

    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.35); shadow.shadowBlurRadius = 24; shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor.black.setFill(); bodyPath.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(colors: [NSColor(srgbRed: 0.20, green: 0.22, blue: 0.26, alpha: 1), NSColor(srgbRed: 0.05, green: 0.06, blue: 0.07, alpha: 1)])!.draw(in: bodyPath, angle: -90)

    NSGraphicsContext.saveGraphicsState()
    bodyPath.addClip()
    let glow = NSGradient(colors: [NSColor(srgbRed: 0.18, green: 0.85, blue: 0.45, alpha: 0.28), NSColor(srgbRed: 0.18, green: 0.85, blue: 0.45, alpha: 0)])!
    glow.draw(fromCenter: NSPoint(x: 512, y: 470), radius: 0, toCenter: NSPoint(x: 512, y: 470), radius: 430, options: [])
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.10).setStroke()
    let rim = NSBezierPath(roundedRect: body.insetBy(dx: 2, dy: 2), xRadius: 183, yRadius: 183); rim.lineWidth = 4; rim.stroke()

    let island = CGRect(x: 192, y: 600, width: 640, height: 196)
    let islandPath = NSBezierPath(roundedRect: island, xRadius: 98, yRadius: 98)
    NSColor.black.setFill(); islandPath.fill()
    NSColor.white.withAlphaComponent(0.14).setStroke(); islandPath.lineWidth = 4; islandPath.stroke()

    let ringCenter = NSPoint(x: 312, y: 698)
    let track = NSBezierPath(); track.appendArc(withCenter: ringCenter, radius: 58, startAngle: 0, endAngle: 360)
    track.lineWidth = 20; NSColor.white.withAlphaComponent(0.16).setStroke(); track.stroke()
    let arc = NSBezierPath(); arc.appendArc(withCenter: ringCenter, radius: 58, startAngle: 90, endAngle: 90 - 270, clockwise: true)
    arc.lineWidth = 20; arc.lineCapStyle = .round; NSColor(srgbRed: 0.20, green: 0.88, blue: 0.47, alpha: 1).setStroke(); arc.stroke()

    NSColor.white.withAlphaComponent(0.92).setFill()
    NSBezierPath(roundedRect: CGRect(x: 412, y: 712, width: 330, height: 34), xRadius: 17, yRadius: 17).fill()
    NSColor.white.withAlphaComponent(0.38).setFill()
    NSBezierPath(roundedRect: CGRect(x: 412, y: 652, width: 210, height: 26), xRadius: 13, yRadius: 13).fill()

    func bud(_ cx: CGFloat, _ mirror: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: cx, y: 360); ctx.scaleBy(x: mirror, y: 1); ctx.rotate(by: -0.18)
        let stem = NSBezierPath(roundedRect: CGRect(x: -26, y: -150, width: 52, height: 170), xRadius: 26, yRadius: 26)
        NSGradient(colors: [NSColor(white: 0.97, alpha: 1), NSColor(white: 0.72, alpha: 1)])!.draw(in: stem, angle: 0)
        let head = NSBezierPath(ovalIn: CGRect(x: -62, y: -10, width: 124, height: 110))
        NSGradient(colors: [NSColor(white: 1, alpha: 1), NSColor(white: 0.78, alpha: 1)])!.draw(in: head, angle: -60)
        let tip = NSBezierPath(ovalIn: CGRect(x: 18, y: 26, width: 56, height: 48))
        NSColor(white: 0.32, alpha: 1).setFill(); tip.fill()
        ctx.restoreGState()
    }
    bud(420, 1); bud(604, -1)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: URL(fileURLWithPath: "\(out)/icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: URL(fileURLWithPath: "\(out)/icon_\(base)x\(base)@2x.png"))
}
