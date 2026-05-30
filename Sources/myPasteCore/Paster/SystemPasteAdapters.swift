#if canImport(AppKit)
import AppKit
import CoreGraphics
import Foundation

public final class NSWorkspaceActivator: AppActivator, @unchecked Sendable {
    public init() {}
    public func activate(pid: Int32) {
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else { return }
        app.activate(options: [])
    }
}

public final class CGEventPasteEmitter: KeyEventEmitter, @unchecked Sendable {
    public init() {}
    public func sendPasteShortcut() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09

        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
#endif
