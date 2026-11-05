// Renders the app icon (orange kitchen timer) and writes the AppIcon asset set.
// Usage: swift Tools/make-icon.swift   (run from the repo root)
import AppKit

let size = 1024
let outDir = "EggTimer/Assets.xcassets/AppIcon.appiconset"

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Work in top-left coordinates.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fillGradient(_ path: CGPath, top: UInt32, bottom: UInt32, in rect: CGRect) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let g = CGGradient(colorsSpace: space, colors: [color(top), color(bottom)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: rect.minY), end: CGPoint(x: 0, y: rect.maxY), options: [])
    ctx.restoreGState()
}

// Body (macOS icon grid: 824pt rounded square centered in 1024).
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = rounded(body, 185)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 24, color: color(0x000000, 0.30))
ctx.addPath(bodyPath)
ctx.setFillColor(color(0xF57A10))
ctx.fillPath()
ctx.restoreGState()
fillGradient(bodyPath, top: 0xFF9A3C, bottom: 0xEE6A05, in: body)

// LCD window.
let lcd = CGRect(x: 175, y: 195, width: 674, height: 370)
let lcdPath = rounded(lcd, 48)
fillGradient(lcdPath, top: 0xC4CAC8, bottom: 0xA9B1AF, in: lcd)
ctx.addPath(lcdPath)
ctx.setStrokeColor(color(0x5E3A12, 0.35))
ctx.setLineWidth(8)
ctx.strokePath()

// Seven-segment digits.
let segmentsFor: [Character: String] = [
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
    "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg",
]

func drawDigit(_ ch: Character, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, t: CGFloat) {
    let gap = t * 0.18
    let horizW = w - t - 2 * gap
    let vertH = h / 2 - t / 2 - 2 * gap
    let rects: [Character: CGRect] = [
        "a": CGRect(x: x + t / 2 + gap, y: y, width: horizW, height: t),
        "g": CGRect(x: x + t / 2 + gap, y: y + h / 2 - t / 2, width: horizW, height: t),
        "d": CGRect(x: x + t / 2 + gap, y: y + h - t, width: horizW, height: t),
        "f": CGRect(x: x, y: y + t / 2 + gap, width: t, height: vertH),
        "b": CGRect(x: x + w - t, y: y + t / 2 + gap, width: t, height: vertH),
        "e": CGRect(x: x, y: y + h / 2 + gap, width: t, height: vertH),
        "c": CGRect(x: x + w - t, y: y + h / 2 + gap, width: t, height: vertH),
    ]
    let lit = segmentsFor[ch] ?? ""
    for (name, r) in rects {
        ctx.addPath(rounded(r, t / 2))
        ctx.setFillColor(lit.contains(name) ? color(0x1F2B35) : color(0x1F2B35, 0.07))
        ctx.fillPath()
    }
}

// Big minutes, small seconds — like the real timer.
drawDigit("0", x: 250, y: 255, w: 130, h: 250, t: 34)
drawDigit("5", x: 400, y: 255, w: 130, h: 250, t: 34)
drawDigit("0", x: 570, y: 345, w: 90, h: 160, t: 24)
drawDigit("0", x: 680, y: 345, w: 90, h: 160, t: 24)

// Buttons.
func button(cx: CGFloat, cy: CGFloat, r: CGFloat) {
    let rect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 6), blur: 10, color: color(0x7A3300, 0.45))
    ctx.addEllipse(in: rect)
    ctx.setFillColor(color(0x2E95E6))
    ctx.fillPath()
    ctx.restoreGState()
    fillGradient(CGPath(ellipseIn: rect, transform: nil), top: 0x5BBDFA, bottom: 0x2A88DA, in: rect)
}
button(cx: 290, cy: 735, r: 64)
button(cx: 470, cy: 735, r: 64)
button(cx: 715, cy: 735, r: 80)

// Write PNGs.
let master = ctx.makeImage()!
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func writePNG(_ px: Int, _ name: String) {
    let c = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.draw(master, in: CGRect(x: 0, y: 0, width: px, height: px))
    let rep = NSBitmapImageRep(cgImage: c.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}

var images: [[String: String]] = []
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(pt)x\(pt)\(scale == 2 ? "@2x" : "").png"
        writePNG(pt * scale, name)
        images.append(["idiom": "mac", "size": "\(pt)x\(pt)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))
try! #"{"info":{"author":"xcode","version":1}}"#.write(
    toFile: "EggTimer/Assets.xcassets/Contents.json", atomically: true, encoding: .utf8)
print("Wrote \(outDir)")
