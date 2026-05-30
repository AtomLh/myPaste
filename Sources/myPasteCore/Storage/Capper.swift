import Foundation

public final class Capper: Sendable {
    private let store: HistoryStore
    private let maxItems: Int
    private let fileRemover: @Sendable (URL) -> Void

    public init(store: HistoryStore, maxItems: Int,
                fileRemover: @escaping @Sendable (URL) -> Void) {
        self.store = store
        self.maxItems = maxItems
        self.fileRemover = fileRemover
    }

    public func trimIfNeeded() throws {
        let total = try store.count()
        guard total > maxItems else { return }
        let kept = try store.fetchRecent(limit: maxItems)
        let keepIds = Set(kept.map(\.id))
        let removedUrls = try store.deleteAllExcept(idsToKeep: keepIds)
        for url in removedUrls { fileRemover(url) }
    }
}
