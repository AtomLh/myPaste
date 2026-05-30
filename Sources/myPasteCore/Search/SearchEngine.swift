import Foundation

public struct SearchEngine: Sendable {
    public init() {}

    public func filter(items: [ClipboardItem], query rawQuery: String) -> [ClipboardItem] {
        let q = rawQuery.lowercased()
        if q.isEmpty { return items }

        struct Scored {
            let item: ClipboardItem
            let rank: Int
        }

        var scored: [Scored] = []
        for item in items where item.kind == .text {
            let preview = item.preview.lowercased()
            if preview.hasPrefix(q) {
                scored.append(Scored(item: item, rank: 0))
            } else if preview.contains(q) {
                scored.append(Scored(item: item, rank: 1))
            }
        }
        scored.sort { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            return lhs.item.createdAt > rhs.item.createdAt
        }
        return scored.map(\.item)
    }
}
