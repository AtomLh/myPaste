import Foundation

public protocol Clock: Sendable {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date { Date() }
}

public final class FakeClock: Clock, @unchecked Sendable {
    private var current: Date
    private let lock = NSLock()
    public init(_ start: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.current = start
    }
    public func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }
    public func advance(by interval: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(interval)
    }
    public func set(_ date: Date) {
        lock.lock(); defer { lock.unlock() }
        current = date
    }
}
