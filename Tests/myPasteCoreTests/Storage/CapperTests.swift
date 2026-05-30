import XCTest
@testable import myPasteCore

final class CapperTests: XCTestCase {
    var tempDir: TempDirectory!
    var store: GRDBHistoryStore!
    var capper: Capper!

    override func setUpWithError() throws {
        tempDir = TempDirectory()
        store = try GRDBHistoryStore(
            databaseURL: tempDir.url.appendingPathComponent("c.sqlite"))
        capper = Capper(store: store, maxItems: 3,
                        fileRemover: { _ in })
    }

    override func tearDown() { capper = nil; store = nil; tempDir = nil }

    private func textItem(_ s: String, at t: TimeInterval) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .text,
                      createdAt: Date(timeIntervalSince1970: t),
                      sourceApp: nil, preview: s,
                      contentHash: s, payload: .text(s))
    }

    func test_underCap_doesNothing() throws {
        try store.insert(textItem("a", at: 1))
        try store.insert(textItem("b", at: 2))
        try capper.trimIfNeeded()
        XCTAssertEqual(try store.count(), 2)
    }

    func test_overCap_keepsOnlyNewestN() throws {
        for i in 1...5 { try store.insert(textItem("i\(i)", at: TimeInterval(i))) }
        try capper.trimIfNeeded()
        XCTAssertEqual(try store.count(), 3)
        let kept = try store.fetchRecent(limit: 10).map(\.preview)
        XCTAssertEqual(kept, ["i5", "i4", "i3"])
    }

    func test_evictedImageFiles_arePassedToRemover() throws {
        let removed = URLBox()
        let cap = Capper(store: store, maxItems: 2,
                         fileRemover: { removed.append($0) })

        let url1 = URL(fileURLWithPath: "/tmp/old.png")
        let url2 = URL(fileURLWithPath: "/tmp/new.png")
        try store.insert(ClipboardItem(id: UUID(), kind: .image,
                                       createdAt: Date(timeIntervalSince1970: 1),
                                       sourceApp: nil, preview: "1",
                                       contentHash: "h1",
                                       payload: .imageRef(url1)))
        try store.insert(textItem("text", at: 2))
        try store.insert(ClipboardItem(id: UUID(), kind: .image,
                                       createdAt: Date(timeIntervalSince1970: 3),
                                       sourceApp: nil, preview: "3",
                                       contentHash: "h3",
                                       payload: .imageRef(url2)))
        try cap.trimIfNeeded()
        XCTAssertEqual(try store.count(), 2)
        XCTAssertEqual(removed.values, [url1])
    }
}

fileprivate final class URLBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [URL] = []
    func append(_ url: URL) {
        lock.lock(); defer { lock.unlock() }
        _values.append(url)
    }
    var values: [URL] {
        lock.lock(); defer { lock.unlock() }
        return _values
    }
}
