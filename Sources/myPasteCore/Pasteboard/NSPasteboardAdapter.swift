#if canImport(AppKit)
import AppKit
import Foundation

public final class NSPasteboardReaderImpl: PasteboardReader, @unchecked Sendable {
    private let pasteboard: NSPasteboard
    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var changeCount: Int { pasteboard.changeCount }

    public func currentContent() -> RawPasteboardContent? {
        let types = (pasteboard.types ?? []).map(\.rawValue)
        let string = pasteboard.string(forType: .string)
        let imageData: Data? = {
            if let d = pasteboard.data(forType: .png) { return d }
            if let d = pasteboard.data(forType: .tiff) { return d }
            return nil
        }()
        let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return RawPasteboardContent(types: types,
                                    string: string,
                                    imageData: imageData,
                                    frontmostAppBundleId: app)
    }
}

public final class NSPasteboardWriterImpl: PasteboardWriter, @unchecked Sendable {
    private let pasteboard: NSPasteboard
    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }
    public func write(_ payload: ClipboardItem.Payload) throws {
        pasteboard.clearContents()
        switch payload {
        case .text(let s):
            pasteboard.setString(s, forType: .string)
        case .imageRef(let url):
            if let data = try? Data(contentsOf: url) {
                pasteboard.setData(data, forType: .png)
            }
        }
    }
}
#endif
