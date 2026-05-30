import AppKit
import ClipSaverCore
import Foundation

@MainActor
final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private let isMonitoringEnabled: () -> Bool
    private let onContentChange: (ClipboardContent) -> Void
    private var timer: Timer?
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        isMonitoringEnabled: @escaping () -> Bool,
        onContentChange: @escaping (ClipboardContent) -> Void
    ) {
        self.pasteboard = pasteboard
        self.isMonitoringEnabled = isMonitoringEnabled
        self.onContentChange = onContentChange
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        guard isMonitoringEnabled() else {
            return
        }

        guard let content = ClipboardReader.readPreferredContent(from: pasteboard) else {
            return
        }

        onContentChange(content)
    }
}
