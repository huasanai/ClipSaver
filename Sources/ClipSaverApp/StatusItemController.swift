import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let appState: AppState
    private let settingsWindowController: SettingsWindowController
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cancellable: AnyCancellable?

    init(appState: AppState, settingsWindowController: SettingsWindowController) {
        self.appState = appState
        self.settingsWindowController = settingsWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        configureStatusButton()
        menu.delegate = self
        statusItem.menu = menu

        cancellable = appState.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.configureStatusButton()
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: appState.statusSymbolName,
            accessibilityDescription: appState.statusTitle
        )
        button.title = " ClipSaver"
        button.imagePosition = .imageLeft
        button.toolTip = "ClipSaver - \(appState.statusTitle)"
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let statusItem = NSMenuItem(title: appState.statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        let messageItem = NSMenuItem(title: appState.lastStatusMessage, action: nil, keyEquivalent: "")
        messageItem.isEnabled = false
        menu.addItem(messageItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: appState.toggleTitle,
            action: #selector(toggleMonitoring),
            keyEquivalent: ""
        ).targeting(self))
        menu.addItem(NSMenuItem(
            title: "打开保存文件夹",
            action: #selector(openSaveDirectory),
            keyEquivalent: ""
        ).targeting(self))
        menu.addItem(NSMenuItem(
            title: "设置...",
            action: #selector(showSettings),
            keyEquivalent: ","
        ).targeting(self))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        ).targeting(self))
    }

    @objc private func toggleMonitoring() {
        appState.toggleMonitoring()
    }

    @objc private func openSaveDirectory() {
        appState.openSaveDirectory()
    }

    @objc private func showSettings() {
        settingsWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private extension NSMenuItem {
    func targeting(_ target: AnyObject) -> NSMenuItem {
        self.target = target
        return self
    }
}
