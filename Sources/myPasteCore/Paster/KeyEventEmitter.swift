import Foundation

public protocol KeyEventEmitter: Sendable {
    func sendPasteShortcut()
}
