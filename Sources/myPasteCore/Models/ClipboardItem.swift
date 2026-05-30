import Foundation

public enum ClipboardKind: String, Codable, Sendable {
    case text
    case image
}

public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: ClipboardKind
    public let createdAt: Date
    public let sourceApp: String?
    public let preview: String
    public let contentHash: String
    public let payload: Payload

    public enum Payload: Equatable, Sendable {
        case text(String)
        case imageRef(URL)
    }

    public init(id: UUID, kind: ClipboardKind, createdAt: Date,
                sourceApp: String?, preview: String, contentHash: String,
                payload: Payload) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.sourceApp = sourceApp
        self.preview = preview
        self.contentHash = contentHash
        self.payload = payload
    }
}
