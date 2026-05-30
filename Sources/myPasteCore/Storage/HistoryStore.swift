import Foundation

public protocol HistoryStore: Sendable {
    func insert(_ item: ClipboardItem) throws
    func fetchRecent(limit: Int) throws -> [ClipboardItem]
    func recentHashes(limit: Int) throws -> [String]
    func touch(id: UUID, newCreatedAt: Date) throws
    func deleteAllExcept(idsToKeep: Set<UUID>) throws -> [URL]
    func count() throws -> Int
}
