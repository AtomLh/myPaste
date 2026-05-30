import AppKit

public final class HUDWindow: NSPanel {
    public init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 300),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false
    }

    public override var canBecomeKey: Bool { true }
}
