import Foundation
import KeyboardShortcuts

@MainActor
final class GlobalShortcutController {
    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        KeyboardShortcuts.onKeyUp(for: .toggleMonitoring) { [weak self] in
            Task { @MainActor in
                self?.onToggle()
            }
        }
    }
}
