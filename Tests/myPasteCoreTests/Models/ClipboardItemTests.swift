import XCTest
@testable import myPasteCore

final class ClipboardItemTests: XCTestCase {
    func test_textItem_equatable_matchesOnSameId() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = ClipboardItem(id: id, kind: .text, createdAt: date,
                              sourceApp: "com.apple.Safari",
                              preview: "hello", contentHash: "abc",
                              payload: .text("hello"))
        let b = ClipboardItem(id: id, kind: .text, createdAt: date,
                              sourceApp: "com.apple.Safari",
                              preview: "hello", contentHash: "abc",
                              payload: .text("hello"))
        XCTAssertEqual(a, b)
    }

    func test_imageItem_equatable_differsByPayload() {
        let id = UUID()
        let now = Date()
        let url1 = URL(fileURLWithPath: "/tmp/a.png")
        let url2 = URL(fileURLWithPath: "/tmp/b.png")
        let a = ClipboardItem(id: id, kind: .image, createdAt: now,
                              sourceApp: nil, preview: "100×100",
                              contentHash: "h", payload: .imageRef(url1))
        let b = ClipboardItem(id: id, kind: .image, createdAt: now,
                              sourceApp: nil, preview: "100×100",
                              contentHash: "h", payload: .imageRef(url2))
        XCTAssertNotEqual(a, b)
    }

    func test_clipboardKind_rawValuesMatchSchema() {
        XCTAssertEqual(ClipboardKind.text.rawValue, "text")
        XCTAssertEqual(ClipboardKind.image.rawValue, "image")
    }
}
