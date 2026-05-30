import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var settingsWindowController: SettingsWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsWindowController = SettingsWindowController(appState: appState)
        self.settingsWindowController = settingsWindowController
        statusItemController = StatusItemController(
            appState: appState,
            settingsWindowController: settingsWindowController
        )

        if !CommandLine.arguments.contains("--background") {
            settingsWindowController.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindowController?.show()
        return true
    }
}
