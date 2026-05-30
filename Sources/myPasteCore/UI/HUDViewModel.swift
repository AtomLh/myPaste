import Foundation

public final class HUDViewModel: @unchecked Sendable {
    public protocol ItemLoader: Sendable {
        func load() throws -> [ClipboardItem]
    }

    private let loader: ItemLoader
    private let search: SearchEngine
    private var allItems: [ClipboardItem] = []
    public private(set) var visibleItems: [ClipboardItem] = []
    public private(set) var query: String = ""

    public init(loader: ItemLoader, search: SearchEngine = SearchEngine()) {
        self.loader = loader
        self.search = search
    }

    public func refresh() throws {
        allItems = try loader.load()
        recompute()
    }

    public func setQuery(_ q: String) {
        query = q
        recompute()
    }

    private func recompute() {
        visibleItems = search.filter(items: allItems, query: query)
    }
}
