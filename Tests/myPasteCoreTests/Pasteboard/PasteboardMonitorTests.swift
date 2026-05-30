import XCTest
@testable import myPasteCore

fileprivate final class Capture: @unchecked Sendable {
    var items: [RawPasteboardContent] = []
    let lock = NSLock()
    func append(_ c: RawPasteboardContent) {
        lock.lock(); defer { lock.unlock() }
        items.append(c)
    }
    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return items.count
    }
}

final class PasteboardMonitorTests: XCTestCase {
    var reader: FakePasteboardReader!
    fileprivate var capture: Capture!
    var monitor: PasteboardMonitor!

    override func setUp() {
        reader = FakePasteboardReader()
        capture = Capture()
        let cap = capture!
        monitor = PasteboardMonitor(reader: reader,
                                    filter: SensitiveFilter(),
                                    onChange: { cap.append($0) })
    }

    func test_initialTick_doesNotEmit_butSetsBaseline() {
        reader.changeCount = 5
        monitor.tick()
        XCTAssertEqual(capture.count, 0)
    }

    func test_changeCountIncreases_emitsContent() {
        reader.changeCount = 0
        monitor.tick()
        reader.changeCount = 1
        reader.contentByChangeCount[1] = RawPasteboardContent(
            types: ["public.utf8-plain-text"], string: "hello",
            imageData: nil, frontmostAppBundleId: "com.apple.Safari")
        monitor.tick()
        XCTAssertEqual(capture.count, 1)
        XCTAssertEqual(capture.items[0].string, "hello")
    }

    func test_sameChangeCount_doesNotEmit() {
        reader.changeCount = 1
        monitor.tick()
        monitor.tick()
        monitor.tick()
        XCTAssertEqual(capture.count, 0)
    }

    func test_sensitiveContent_isFiltered() {
        reader.changeCount = 0
        monitor.tick()
        reader.changeCount = 1
        reader.contentByChangeCount[1] = RawPasteboardContent(
            types: ["org.nspasteboard.ConcealedType"], string: "pw",
            imageData: nil, frontmostAppBundleId: nil)
        monitor.tick()
        XCTAssertEqual(capture.count, 0)
    }

    func test_ignoreNextChange_skipsOneEmission() {
        reader.changeCount = 0
        monitor.tick()
        monitor.ignoreNextChange()
        reader.changeCount = 1
        reader.contentByChangeCount[1] = RawPasteboardContent(
            types: ["public.utf8-plain-text"], string: "own write",
            imageData: nil, frontmostAppBundleId: nil)
        monitor.tick()
        XCTAssertEqual(capture.count, 0)

        reader.changeCount = 2
        reader.contentByChangeCount[2] = RawPasteboardContent(
            types: ["public.utf8-plain-text"], string: "real",
            imageData: nil, frontmostAppBundleId: nil)
        monitor.tick()
        XCTAssertEqual(capture.items.map(\.string), ["real"])
    }
}
