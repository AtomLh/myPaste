import XCTest
import CoreGraphics
import ImageIO
@testable import myPasteCore

final class ImageBlobStoreTests: XCTestCase {
    var tempDir: TempDirectory!
    var store: ImageBlobStore!

    override func setUpWithError() throws {
        tempDir = TempDirectory()
        store = ImageBlobStore(rootDirectory: tempDir.url,
                               maxLongEdge: 4096,
                               maxRawBytesBeforeDownscale: 10 * 1024 * 1024)
    }

    override func tearDown() { store = nil; tempDir = nil }

    private func makePNGData(width: Int, height: Int) -> Data {
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: width, height: height,
                            bitsPerComponent: 8, bytesPerRow: 0,
                            space: cs,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = ctx.makeImage()!
        let nsData = NSMutableData()
        let dest = CGImageDestinationCreateWithData(
            nsData, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        return nsData as Data
    }

    func test_save_writesFileAndReturnsURL() throws {
        let data = makePNGData(width: 100, height: 80)
        let (url, dims) = try store.save(pngData: data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(dims.width, 100)
        XCTAssertEqual(dims.height, 80)
    }

    func test_save_smallImage_doesNotDownscale() throws {
        let data = makePNGData(width: 200, height: 100)
        let (url, dims) = try store.save(pngData: data)
        XCTAssertEqual(dims.width, 200)
        XCTAssertEqual(dims.height, 100)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertGreaterThan(attrs[.size] as! Int, 0)
    }

    func test_save_oversizedImage_downscalesLongEdgeToMax() throws {
        let s = ImageBlobStore(rootDirectory: tempDir.url,
                               maxLongEdge: 200,
                               maxRawBytesBeforeDownscale: 1)
        let data = makePNGData(width: 1000, height: 500)
        let (_, dims) = try s.save(pngData: data)
        XCTAssertEqual(dims.width, 200)
        XCTAssertEqual(dims.height, 100)
    }
}
