import Foundation

public final class Paster: Sendable {
    private let writer: PasteboardWriter
    private let activator: AppActivator
    private let emitter: KeyEventEmitter
    private let ignoreNextMonitorChange: @Sendable () -> Void

    public init(writer: PasteboardWriter,
                activator: AppActivator,
                emitter: KeyEventEmitter,
                ignoreNextMonitorChange: @escaping @Sendable () -> Void) {
        self.writer = writer
        self.activator = activator
        self.emitter = emitter
        self.ignoreNextMonitorChange = ignoreNextMonitorChange
    }

    public func paste(_ payload: ClipboardItem.Payload, activatePid: Int32?) throws {
        ignoreNextMonitorChange()
        try writer.write(payload)
        if let pid = activatePid {
            activator.activate(pid: pid)
        }
        emitter.sendPasteShortcut()
    }
}
