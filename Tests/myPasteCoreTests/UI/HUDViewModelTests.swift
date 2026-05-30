import XCTest
@testable import myPasteCore

final class HUDViewModelTests: XCTestCase {

    final class StubLoader: HUDViewModel.ItemLoader, @unchecked Sendable {
        var items: [ClipboardItem] = []
        func load() throws -> [ClipboardItem] { items }
    }

    private func text(_ s: String, at t: TimeInterval) -> ClipboardItem {
        ClipboardItem(id: UUID(), kind: .text,
                      createdAt: Date(timeIntervalSince1970: t),
                      sourceApp: nil, preview: s, contentHash: s,
                      payload: .text(s))
    }

    func test_refresh_loadsAndPublishesItems() throws {
        let loader = StubLoader()
        loader.items = [text("a", at: 1), text("b", at: 2)]
        let vm = HUDViewModel(loader: loader, search: SearchEngine())
        try vm.refresh()
        XCTAssertEqual(vm.visibleItems.map(\.preview), ["a", "b"])
    }

    func test_setQuery_appliesSearchFilter() throws {
        let loader = StubLoader()
        loader.items = [text("apple", at: 2), text("banana", at: 1)]
        let vm = HUDViewModel(loader: loader, search: SearchEngine())
        try vm.refresh()
        vm.setQuery("app")
        XCTAssertEqual(vm.visibleItems.map(\.preview), ["apple"])
    }

    func test_clearQuery_restoresAll() throws {
        let loader = StubLoader()
        loader.items = [text("x", at: 1), text("y", at: 2)]
        let vm = HUDViewModel(loader: loader, search: SearchEngine())
        try vm.refresh()
        vm.setQuery("x")
        vm.setQuery("")
        XCTAssertEqual(vm.visibleItems.count, 2)
    }
}
