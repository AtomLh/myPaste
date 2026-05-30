import XCTest
@testable import myPasteCore

final class HistoryRecorderTests: XCTestCase {
    var tempDir: TempDirectory!
    var store: GRDBHistoryStore!
    var clock: FakeClock!
    var recorder: HistoryRecorder!

    override func setUpWithError() throws {
        tempDir = TempDirectory()
        store = try GRDBHistoryStore(databaseURL: tempDir.url.appendingPathComponent("r.sqlite"))
        clock = FakeClock(Date(timeIntervalSince1970: 1_000))
        recorder = HistoryRecorder(store: store, clock: clock, dedupeWindow: 5)
    }

    override func tearDown() {
        recorder = nil; clock = nil; store = nil; tempDir = nil
    }

    private func text(_ s: String) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .text, createdAt: clock.now(),
                      sourceApp: nil, preview: s,
                      contentHash: ContentHasher.hash(s),
                      payload: .text(s))
    }

    func test_newItem_isInserted() throws {
        try recorder.recordOrTouch(text("hello"))
        XCTAssertEqual(try store.count(), 1)
    }

    func test_duplicateOfMostRecent_touchesInsteadOfInserts() throws {
        try recorder.recordOrTouch(text("hello"))
        clock.advance(by: 60)
        try recorder.recordOrTouch(text("hello"))
        XCTAssertEqual(try store.count(), 1)
        let only = try store.fetchRecent(limit: 1).first!
        XCTAssertEqual(only.createdAt, clock.now())
    }

    func test_duplicateOutsideWindow_isInserted() throws {
        for label in ["a", "b", "c", "d", "e"] {
            try recorder.recordOrTouch(text(label))
            clock.advance(by: 1)
        }
        for label in ["x1", "x2", "x3", "x4", "x5"] {
            try recorder.recordOrTouch(text(label))
            clock.advance(by: 1)
        }
        try recorder.recordOrTouch(text("a"))
        XCTAssertEqual(try store.count(), 11)
    }
}
