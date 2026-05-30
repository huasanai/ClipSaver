import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private var window: NSWindow?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let rootView = SettingsView()
            .environmentObject(appState)

        let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
        window.title = "ClipSaver 设置"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(NSSize(width: 620, height: 680))
        window.minSize = NSSize(width: 560, height: 560)
        window.center()
        return window
    }
}
