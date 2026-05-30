import Foundation

public struct RawPasteboardContent: Equatable, Sendable {
    public let types: [String]
    public let string: String?
    public let imageData: Data?
    public let frontmostAppBundleId: String?

    public init(types: [String], string: String?, imageData: Data?,
                frontmostAppBundleId: String?) {
        self.types = types
        self.string = string
        self.imageData = imageData
        self.frontmostAppBundleId = frontmostAppBundleId
    }
}
