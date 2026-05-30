import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleHUD = Self("toggleHUD",
        default: .init(.v, modifiers: [.command, .shift]))
}

public final class HotkeyService {
    private let onTrigger: () -> Void
    public init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }
    public func register() {
        KeyboardShortcuts.onKeyDown(for: .toggleHUD) { [weak self] in
            self?.onTrigger()
        }
    }
}
