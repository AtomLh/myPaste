import Foundation
import GRDB

public final class GRDBHistoryStore: HistoryStore {
    private let dbQueue: DatabaseQueue

    public init(databaseURL: URL) throws {
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        self.dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
        try migrate()
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "clipboard_items") { t in
                t.column("id", .text).primaryKey()
                t.column("kind", .text).notNull()
                t.column("created_at", .double).notNull()
                t.column("source_app", .text)
                t.column("preview", .text).notNull()
                t.column("content_hash", .text).notNull()
                t.column("text_content", .text)
                t.column("image_path", .text)
            }
            try db.create(index: "idx_created_at",
                          on: "clipboard_items", columns: ["created_at"])
            try db.create(index: "idx_content_hash",
                          on: "clipboard_items", columns: ["content_hash"])
        }
        try migrator.migrate(dbQueue)
    }

    public func insert(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO clipboard_items
                (id, kind, created_at, source_app, preview, content_hash, text_content, image_path)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    item.id.uuidString,
                    item.kind.rawValue,
                    item.createdAt.timeIntervalSince1970,
                    item.sourceApp,
                    item.preview,
                    item.contentHash,
                    item.payload.textValue,
                    item.payload.imagePath,
                ])
        }
    }

    public func fetchRecent(limit: Int) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, kind, created_at, source_app, preview, content_hash,
                       text_content, image_path
                FROM clipboard_items
                ORDER BY created_at DESC
                LIMIT ?
                """, arguments: [limit])
            return rows.compactMap(Self.itemFromRow)
        }
    }

    public func recentHashes(limit: Int) throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: """
                SELECT content_hash FROM clipboard_items
                ORDER BY created_at DESC LIMIT ?
                """, arguments: [limit])
        }
    }

    public func touch(id: UUID, newCreatedAt: Date) throws {
        try dbQueue.write { db in
            try db.execute(sql: """
                UPDATE clipboard_items SET created_at = ? WHERE id = ?
                """,
                arguments: [newCreatedAt.timeIntervalSince1970, id.uuidString])
        }
    }

    public func deleteAllExcept(idsToKeep: Set<UUID>) throws -> [URL] {
        try dbQueue.write { db in
            let keepList = idsToKeep.map { $0.uuidString }
            let placeholders = keepList.isEmpty ? "''" :
                keepList.map { _ in "?" }.joined(separator: ",")
            let toDelete = try Row.fetchAll(db, sql: """
                SELECT image_path FROM clipboard_items
                WHERE id NOT IN (\(placeholders)) AND image_path IS NOT NULL
                """, arguments: StatementArguments(keepList))
            let urls: [URL] = toDelete.compactMap { row in
                (row["image_path"] as String?).map(URL.init(fileURLWithPath:))
            }
            try db.execute(sql: """
                DELETE FROM clipboard_items WHERE id NOT IN (\(placeholders))
                """, arguments: StatementArguments(keepList))
            return urls
        }
    }

    public func count() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM clipboard_items") ?? 0
        }
    }

    private static func itemFromRow(_ row: Row) -> ClipboardItem? {
        guard
            let idStr: String = row["id"], let id = UUID(uuidString: idStr),
            let kindStr: String = row["kind"], let kind = ClipboardKind(rawValue: kindStr),
            let ts: Double = row["created_at"],
            let preview: String = row["preview"],
            let hash: String = row["content_hash"]
        else { return nil }

        let payload: ClipboardItem.Payload
        switch kind {
        case .text:
            payload = .text(row["text_content"] ?? "")
        case .image:
            guard let path: String = row["image_path"] else { return nil }
            payload = .imageRef(URL(fileURLWithPath: path))
        }
        return ClipboardItem(
            id: id, kind: kind, createdAt: Date(timeIntervalSince1970: ts),
            sourceApp: row["source_app"], preview: preview,
            contentHash: hash, payload: payload)
    }
}

private extension ClipboardItem.Payload {
    var textValue: String? {
        if case .text(let s) = self { return s } else { return nil }
    }
    var imagePath: String? {
        if case .imageRef(let url) = self { return url.path } else { return nil }
    }
}
