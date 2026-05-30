import Foundation

public protocol PasteboardWriter: Sendable {
    func write(_ payload: ClipboardItem.Payload) throws
}
