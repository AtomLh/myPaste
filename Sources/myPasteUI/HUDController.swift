import AppKit
import SwiftUI
import myPasteCore

public final class HUDController: NSObject {
    private var window: HUDWindow?
    private var previousAppPid: Int32?
    private let viewModel: HUDViewModel
    private let onPaste: (ClipboardItem, Int32?) -> Void
    private var resignObserver: NSObjectProtocol?

    public init(viewModel: HUDViewModel,
                onPaste: @escaping (ClipboardItem, Int32?) -> Void) {
        self.viewModel = viewModel
        self.onPaste = onPaste
    }

    public var isVisible: Bool { window?.isVisible ?? false }

    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func show() {
        previousAppPid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        try? viewModel.refresh()

        let win = window ?? HUDWindow()
        window = win

        let content = HUDView(
            viewModel: viewModel,
            onPaste: { [weak self] item in
                guard let self else { return }
                let pid = self.previousAppPid
                self.hide()
                self.onPaste(item, pid)
            },
            onDismiss: { [weak self] in self?.hide() })
        win.contentView = NSHostingView(rootView: content)

        if let screen = NSScreen.main {
            let maxW: CGFloat = 1300
            let w = min(maxW, screen.frame.width - 40)
            let h: CGFloat = 290
            let x = screen.frame.origin.x + (screen.frame.width - w) / 2
            let y = screen.frame.origin.y + 16
            win.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        }

        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: win,
            queue: nil
        ) { [weak self] _ in
            self?.hide()
        }

        NSApp.presentationOptions = [.autoHideDock]
        win.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    public func hide() {
        if let obs = resignObserver {
            NotificationCenter.default.removeObserver(obs)
            resignObserver = nil
        }
        NSApp.presentationOptions = []
        window?.orderOut(nil)
    }
}
