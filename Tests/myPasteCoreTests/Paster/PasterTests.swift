import XCTest
@testable import myPasteCore

final class PasterTests: XCTestCase {

    final class FakeWriter: PasteboardWriter, @unchecked Sendable {
        var writes: [ClipboardItem.Payload] = []
        func write(_ payload: ClipboardItem.Payload) throws { writes.append(payload) }
    }
    final class FakeActivator: AppActivator, @unchecked Sendable {
        var activatedPid: Int32?
        func activate(pid: Int32) { activatedPid = pid }
    }
    final class FakeEmitter: KeyEventEmitter, @unchecked Sendable {
        var emitCount = 0
        func sendPasteShortcut() { emitCount += 1 }
    }

    func test_paste_writesAndActivatesAndEmits() throws {
        let writer = FakeWriter()
        let activator = FakeActivator()
        let emitter = FakeEmitter()
        let ignoreBox = IgnoreBox()

        let paster = Paster(writer: writer,
                            activator: activator,
                            emitter: emitter,
                            ignoreNextMonitorChange: { ignoreBox.bump() })

        try paster.paste(.text("hello"), activatePid: 1234)

        XCTAssertEqual(ignoreBox.count, 1)
        XCTAssertEqual(writer.writes, [.text("hello")])
        XCTAssertEqual(activator.activatedPid, 1234)
        XCTAssertEqual(emitter.emitCount, 1)
    }

    func test_paste_withNilPid_skipsActivation() throws {
        let writer = FakeWriter()
        let activator = FakeActivator()
        let emitter = FakeEmitter()

        let paster = Paster(writer: writer,
                            activator: activator,
                            emitter: emitter,
                            ignoreNextMonitorChange: {})

        try paster.paste(.text("hi"), activatePid: nil)

        XCTAssertEqual(writer.writes, [.text("hi")])
        XCTAssertNil(activator.activatedPid)
        XCTAssertEqual(emitter.emitCount, 1)
    }
}

fileprivate final class IgnoreBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    func bump() { lock.lock(); _count += 1; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return _count }
}
