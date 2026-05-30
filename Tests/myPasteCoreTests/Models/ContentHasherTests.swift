import XCTest
@testable import myPasteCore

final class ContentHasherTests: XCTestCase {
    func test_sameString_producesSameHash() {
        XCTAssertEqual(ContentHasher.hash("hello"),
                       ContentHasher.hash("hello"))
    }

    func test_differentStrings_differentHashes() {
        XCTAssertNotEqual(ContentHasher.hash("hello"),
                          ContentHasher.hash("world"))
    }

    func test_sameBytes_producesSameHash() {
        let a = Data([1, 2, 3, 4])
        let b = Data([1, 2, 3, 4])
        XCTAssertEqual(ContentHasher.hash(a), ContentHasher.hash(b))
    }

    func test_hashIsLowercaseHex_64chars() {
        let h = ContentHasher.hash("anything")
        XCTAssertEqual(h.count, 64)
        XCTAssertTrue(h.allSatisfy { "0123456789abcdef".contains($0) })
    }
}
