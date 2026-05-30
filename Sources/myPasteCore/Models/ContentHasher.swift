import Foundation
import CryptoKit

public enum ContentHasher {
    public static func hash(_ string: String) -> String {
        hash(Data(string.utf8))
    }

    public static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
