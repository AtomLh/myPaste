import XCTest
@testable import myPasteCore

final class SearchEngineTests: XCTestCase {
    private func textItem(_ s: String, at t: TimeInterval) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .text,
                      createdAt: Date(timeIntervalSince1970: t),
                      sourceApp: nil, preview: s,
                      contentHash: s, payload: .text(s))
    }
    private func imageItem(at t: TimeInterval) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .image,
                      createdAt: Date(timeIntervalSince1970: t),
                      sourceApp: nil, preview: "100×100",
                      contentHash: "h\(t)",
                      payload: .imageRef(URL(fileURLWithPath: "/tmp/\(t).png")))
    }

    func test_emptyQuery_returnsAllInOriginalOrder() {
        let items = [textItem("a", at: 3), imageItem(at: 2), textItem("b", at: 1)]
        let result = SearchEngine().filter(items: items, query: "")
        XCTAssertEqual(result.map(\.preview), ["a", "100×100", "b"])
    }

    func test_substringMatch_caseInsensitive() {
        let items = [textItem("Hello world", at: 1), textItem("Goodbye", at: 2)]
        let result = SearchEngine().filter(items: items, query: "HELLO")
        XCTAssertEqual(result.map(\.preview), ["Hello world"])
    }

    func test_prefixMatchesRankBeforeSubstring() {
        let items = [
            textItem("zoo apple", at: 5),
            textItem("apple zoo", at: 1),
        ]
        let result = SearchEngine().filter(items: items, query: "apple")
        XCTAssertEqual(result.map(\.preview), ["apple zoo", "zoo apple"])
    }

    func test_tiesBrokenByCreatedAtDesc() {
        let items = [
            textItem("apple a", at: 1),
            textItem("apple b", at: 2),
        ]
        let result = SearchEngine().filter(items: items, query: "apple")
        XCTAssertEqual(result.map(\.preview), ["apple b", "apple a"])
    }

    func test_imagesExcludedWhenQueryNonEmpty() {
        let items = [textItem("hello", at: 1), imageItem(at: 2)]
        let result = SearchEngine().filter(items: items, query: "h")
        XCTAssertEqual(result.map(\.preview), ["hello"])
    }
}
