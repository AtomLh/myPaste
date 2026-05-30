#!/usr/bin/env swift
import Foundation
import AppKit

let outDir = ProcessInfo.processInfo.arguments.count > 1
    ? ProcessInfo.processInfo.arguments[1]
    : "build/myPaste.iconset"

try? FileManager.default.removeItem(atPath: outDir)
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func renderIcon(size: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }

    guard let gctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext

    let s = CGFloat(size)
    let accent = NSColor(srgbRed: 0.30, green: 0.36, blue: 0.93, alpha: 1).cgColor

    ctx.setFillColor(accent)
    let radius = s * 0.22
    ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                       cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.fillPath()

    let bodyW = s * 0.58
    let bodyH = s * 0.68
    let bodyX = (s - bodyW) / 2
    let bodyY = (s - bodyH) / 2 - s * 0.03
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.addPath(CGPath(roundedRect: CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH),
                       cornerWidth: s*0.05, cornerHeight: s*0.05, transform: nil))
    ctx.fillPath()

    let clipW = bodyW * 0.45
    let clipH = s * 0.11
    let clipX = (s - clipW) / 2
    let clipY = bodyY + bodyH - clipH * 0.35
    ctx.setFillColor(accent)
    ctx.addPath(CGPath(roundedRect: CGRect(x: clipX, y: clipY, width: clipW, height: clipH),
                       cornerWidth: clipH*0.4, cornerHeight: clipH*0.4, transform: nil))
    ctx.fillPath()

    ctx.setFillColor(NSColor(srgbRed: 0.70, green: 0.74, blue: 0.80, alpha: 1).cgColor)
    let lineW = bodyW * 0.7
    let lineH = max(2, s * 0.035)
    let lineX = bodyX + (bodyW - lineW) / 2
    let spacing = s * 0.11
    let firstLineY = bodyY + bodyH * 0.55
    for i in 0..<3 {
        let y = firstLineY - CGFloat(i) * spacing
        ctx.fill(CGRect(x: lineX, y: y, width: lineW, height: lineH))
    }

    return rep.representation(using: .png, properties: [:])
}

let names: [(Int, String)] = [
    (16,  "icon_16x16.png"),
    (32,  "icon_16x16@2x.png"),
    (32,  "icon_32x32.png"),
    (64,  "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024,"icon_512x512@2x.png"),
]

var cache: [Int: Data] = [:]
for (size, name) in names {
    let data: Data
    if let cached = cache[size] {
        data = cached
    } else {
        guard let d = renderIcon(size: size) else {
            FileHandle.standardError.write("Failed to render \(size)\n".data(using: .utf8)!)
            exit(1)
        }
        cache[size] = d
        data = d
    }
    try data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}

print("Wrote \(names.count) PNGs to \(outDir)")
