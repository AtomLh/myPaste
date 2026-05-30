import AppKit
import Foundation
import myPasteCore
import myPasteUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: PasteboardMonitor?
    private var pollingTimer: Timer?
    private var recorder: HistoryRecorder?
    private var capper: Capper?
    private var imageStore: ImageBlobStore?
    private var hudController: HUDController?
    private var hotkeyService: HotkeyService?
    private var paster: Paster?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("myPaste")
        try? FileManager.default.createDirectory(
            at: appSupport, withIntermediateDirectories: true)

        let dbURL = appSupport.appendingPathComponent("history.sqlite")
        let imagesDir = appSupport.appendingPathComponent("images")
        let store: GRDBHistoryStore
        do { store = try GRDBHistoryStore(databaseURL: dbURL) }
        catch {
            NSLog("myPaste DB error: \(error)")
            return
        }
        imageStore = ImageBlobStore(rootDirectory: imagesDir)
        let clock = SystemClock()
        recorder = HistoryRecorder(store: store, clock: clock, dedupeWindow: 5)
        capper = Capper(store: store, maxItems: 200,
                        fileRemover: { url in
                            try? FileManager.default.removeItem(at: url)
                        })

        let reader = NSPasteboardReaderImpl()
        let writer = NSPasteboardWriterImpl()
        monitor = PasteboardMonitor(
            reader: reader,
            filter: SensitiveFilter(),
            onChange: { [weak self] raw in
                self?.handleClip(raw)
            })

        let viewModel = HUDViewModel(
            loader: StoreLoader(store: store),
            search: SearchEngine())

        paster = Paster(writer: writer,
                        activator: NSWorkspaceActivator(),
                        emitter: CGEventPasteEmitter(),
                        ignoreNextMonitorChange: { [weak self] in
                            self?.monitor?.ignoreNextChange()
                        })

        hudController = HUDController(
            viewModel: viewModel,
            onPaste: { [weak self] item, pid in
                try? self?.paster?.paste(item.payload, activatePid: pid)
            })

        hotkeyService = HotkeyService { [weak self] in
            self?.hudController?.toggle()
        }
        hotkeyService?.register()

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.monitor?.tick()
        }

        if !AXIsProcessTrusted() {
            NSLog("myPaste: Accessibility permission missing — paste-back will not work until granted.")
        }
    }

    private func handleClip(_ raw: RawPasteboardContent) {
        let createdAt = Date()
        let item: ClipboardItem
        if let data = raw.imageData {
            guard let imgStore = imageStore else { return }
            do {
                let (url, dims) = try imgStore.save(pngData: data)
                let hash = ContentHasher.hash(data)
                item = ClipboardItem(
                    id: UUID(), kind: .image, createdAt: createdAt,
                    sourceApp: raw.frontmostAppBundleId,
                    preview: "\(dims.width)×\(dims.height)",
                    contentHash: hash, payload: .imageRef(url))
            } catch { return }
        } else if let s = raw.string, !s.isEmpty {
            let hash = ContentHasher.hash(s)
            let preview = String(s.prefix(200))
            item = ClipboardItem(
                id: UUID(), kind: .text, createdAt: createdAt,
                sourceApp: raw.frontmostAppBundleId,
                preview: preview, contentHash: hash, payload: .text(s))
        } else { return }

        try? recorder?.recordOrTouch(item)
        try? capper?.trimIfNeeded()
    }
}

private struct StoreLoader: HUDViewModel.ItemLoader {
    let store: GRDBHistoryStore
    func load() throws -> [ClipboardItem] {
        try store.fetchRecent(limit: 200)
    }
}
