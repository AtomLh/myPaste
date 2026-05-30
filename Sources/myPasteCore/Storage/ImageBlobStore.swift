import Foundation
import CoreGraphics
import ImageIO

public struct ImageDimensions: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public init(width: Int, height: Int) {
        self.width = width; self.height = height
    }
}

public final class ImageBlobStore: Sendable {
    private let rootDirectory: URL
    private let maxLongEdge: Int
    private let maxRawBytesBeforeDownscale: Int

    public init(rootDirectory: URL,
                maxLongEdge: Int = 4096,
                maxRawBytesBeforeDownscale: Int = 10 * 1024 * 1024) {
        self.rootDirectory = rootDirectory
        self.maxLongEdge = maxLongEdge
        self.maxRawBytesBeforeDownscale = maxRawBytesBeforeDownscale
        try? FileManager.default.createDirectory(at: rootDirectory,
                                                 withIntermediateDirectories: true)
    }

    public enum Error: Swift.Error {
        case decodeFailed
        case encodeFailed
    }

    public func save(pngData: Data) throws -> (URL, ImageDimensions) {
        guard let src = CGImageSourceCreateWithData(pngData as CFData, nil),
              let original = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else { throw Error.decodeFailed }

        let w = original.width, h = original.height
        let needsDownscale =
            pngData.count > maxRawBytesBeforeDownscale ||
            max(w, h) > maxLongEdge

        let cgImage: CGImage
        let outWidth: Int
        let outHeight: Int
        if needsDownscale {
            let longEdge = max(w, h)
            let scale = Double(maxLongEdge) / Double(longEdge)
            outWidth = Int(Double(w) * scale)
            outHeight = Int(Double(h) * scale)
            cgImage = try Self.resize(original, width: outWidth, height: outHeight)
        } else {
            cgImage = original
            outWidth = w; outHeight = h
        }

        let filename = UUID().uuidString + ".png"
        let url = rootDirectory.appendingPathComponent(filename)
        try Self.writePNG(cgImage, to: url)
        return (url, ImageDimensions(width: outWidth, height: outHeight))
    }

    private static func resize(_ image: CGImage, width: Int, height: Int) throws -> CGImage {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw Error.encodeFailed }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let out = ctx.makeImage() else { throw Error.encodeFailed }
        return out
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, "public.png" as CFString, 1, nil)
        else { throw Error.encodeFailed }
        CGImageDestinationAddImage(dest, image, nil)
        if !CGImageDestinationFinalize(dest) { throw Error.encodeFailed }
    }
}
