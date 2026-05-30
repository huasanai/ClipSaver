import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMonitoring = Self(
        "toggleMonitoring",
        default: KeyboardShortcuts.Shortcut(.s, modifiers: [.command, .shift])
    )
}
