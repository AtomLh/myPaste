import Foundation

public final class HistoryRecorder: Sendable {
    private let store: HistoryStore
    private let clock: Clock
    private let dedupeWindow: Int

    public init(store: HistoryStore, clock: Clock, dedupeWindow: Int = 5) {
        self.store = store
        self.clock = clock
        self.dedupeWindow = dedupeWindow
    }

    public func recordOrTouch(_ item: ClipboardItem) throws {
        let recent = try store.recentHashes(limit: dedupeWindow)
        if let matchIndex = recent.firstIndex(of: item.contentHash) {
            let items = try store.fetchRecent(limit: dedupeWindow)
            guard matchIndex < items.count else {
                try store.insert(item); return
            }
            try store.touch(id: items[matchIndex].id, newCreatedAt: clock.now())
        } else {
            try store.insert(item)
        }
    }
}
