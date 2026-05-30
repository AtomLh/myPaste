import Foundation

public protocol AppActivator: Sendable {
    func activate(pid: Int32)
}
