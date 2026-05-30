import Foundation

public protocol PasteboardReader: Sendable {
    var changeCount: Int { get }
    func currentContent() -> RawPasteboardContent?
}
