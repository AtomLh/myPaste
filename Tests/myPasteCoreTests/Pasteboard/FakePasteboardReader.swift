import Foundation
@testable import myPasteCore

final class FakePasteboardReader: PasteboardReader, @unchecked Sendable {
    var changeCount: Int = 0
    var contentByChangeCount: [Int: RawPasteboardContent] = [:]
    func currentContent() -> RawPasteboardContent? {
        contentByChangeCount[changeCount]
    }
}
