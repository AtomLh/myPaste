import XCTest
@testable import myPasteCore

final class GRDBHistoryStoreTests: XCTestCase {
    var tempDir: TempDirectory!
    var store: GRDBHistoryStore!

    override func setUpWithError() throws {
        tempDir = TempDirectory()
        store = try GRDBHistoryStore(databaseURL: tempDir.url.appendingPathComponent("test.sqlite"))
    }

    override func tearDown() {
        store = nil
        tempDir = nil
    }

    private func makeTextItem(_ s: String, at t: TimeInterval) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .text,
                      createdAt: Date(timeIntervalSince1970: t),
                      sourceApp: "com.apple.Safari",
                      preview: s, contentHash: ContentHasher.hash(s),
                      payload: .text(s))
    }

    func test_insertOne_thenFetchRecent_returnsIt() throws {
        let item = makeTextItem("hello", at: 1)
        try store.insert(item)
        let result = try store.fetchRecent(limit: 10)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, item.id)
        XCTAssertEqual(result.first?.preview, "hello")
    }

    func test_fetchRecent_ordersByCreatedAtDescending() throws {
        let older = makeTextItem("older", at: 100)
        let newer = makeTextItem("newer", at: 200)
        try store.insert(older)
        try store.insert(newer)
        let result = try store.fetchRecent(limit: 10)
        XCTAssertEqual(result.map(\.preview), ["newer", "older"])
    }

    func test_fetchRecent_respectsLimit() throws {
        for i in 0..<5 {
            try store.insert(makeTextItem("\(i)", at: TimeInterval(i)))
        }
        let result = try store.fetchRecent(limit: 3)
        XCTAssertEqual(result.count, 3)
    }

    func test_recentHashes_returnsHashesNewestFirst() throws {
        let a = makeTextItem("a", at: 1)
        let b = makeTextItem("b", at: 2)
        try store.insert(a); try store.insert(b)
        let hashes = try store.recentHashes(limit: 5)
        XCTAssertEqual(hashes, [b.contentHash, a.contentHash])
    }

    func test_count_reflectsInsertions() throws {
        XCTAssertEqual(try store.count(), 0)
        try store.insert(makeTextItem("x", at: 1))
        try store.insert(makeTextItem("y", at: 2))
        XCTAssertEqual(try store.count(), 2)
    }

    func test_imageItem_roundtripsImagePath() throws {
        let url = URL(fileURLWithPath: "/tmp/foo.png")
        let item = ClipboardItem(id: UUID(), kind: .image,
                                 createdAt: Date(timeIntervalSince1970: 1),
                                 sourceApp: nil, preview: "100×100",
                                 contentHash: "h",
                                 payload: .imageRef(url))
        try store.insert(item)
        let result = try store.fetchRecent(limit: 1).first
        XCTAssertEqual(result?.kind, .image)
        XCTAssertEqual(result?.payload, .imageRef(url))
    }
}
