import Foundation

public final class PasteboardMonitor: @unchecked Sendable {
    private let reader: PasteboardReader
    private let filter: SensitiveFilter
    private let onChange: @Sendable (RawPasteboardContent) -> Void
    private let lock = NSLock()
    private var lastChangeCount: Int?
    private var ignoreNextValue: Bool = false

    public init(reader: PasteboardReader,
                filter: SensitiveFilter = SensitiveFilter(),
                onChange: @escaping @Sendable (RawPasteboardContent) -> Void) {
        self.reader = reader
        self.filter = filter
        self.onChange = onChange
    }

    public func ignoreNextChange() {
        lock.lock(); defer { lock.unlock() }
        ignoreNextValue = true
    }

    public func tick() {
        lock.lock()
        let current = reader.changeCount
        let prior = lastChangeCount
        lastChangeCount = current
        let shouldIgnore = ignoreNextValue
        if prior == nil {
            lock.unlock(); return
        }
        if current == prior {
            lock.unlock(); return
        }
        if shouldIgnore {
            ignoreNextValue = false
            lock.unlock(); return
        }
        lock.unlock()

        guard let content = reader.currentContent() else { return }
        if filter.shouldSkip(content) { return }
        onChange(content)
    }
}
