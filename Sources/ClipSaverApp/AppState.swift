import AppKit
import ClipSaverCore
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isMonitoringEnabled: Bool
    @Published private(set) var saveText: Bool
    @Published private(set) var saveImages: Bool
    @Published private(set) var saveFiles: Bool
    @Published private(set) var saveDirectoryPath: String
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var lastStatusMessage = "Ready"

    private let defaults: UserDefaults
    private let saveQueue = DispatchQueue(label: "dev.huasan.clipsaver.save", qos: .utility)
    private var monitor: ClipboardMonitor?
    private var shortcutController: GlobalShortcutController?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        AppDefaults.register(in: defaults)

        isMonitoringEnabled = defaults.bool(forKey: AppSettingKey.isMonitoringEnabled)
        saveText = defaults.bool(forKey: AppSettingKey.saveText)
        saveImages = defaults.bool(forKey: AppSettingKey.saveImages)
        saveFiles = defaults.bool(forKey: AppSettingKey.saveFiles)
        saveDirectoryPath = defaults.string(forKey: AppSettingKey.saveDirectoryPath) ?? AppDefaults.saveDirectoryPath
        launchAtLogin = LaunchAgentManager.shared.isEnabled
        defaults.set(launchAtLogin, forKey: AppSettingKey.launchAtLogin)

        monitor = ClipboardMonitor(
            isMonitoringEnabled: { [weak self] in
                self?.isMonitoringEnabled ?? false
            },
            onContentChange: { [weak self] content in
                self?.save(content)
            }
        )

        shortcutController = GlobalShortcutController { [weak self] in
            self?.toggleMonitoring()
        }

        monitor?.start()
    }

    var saveDirectoryURL: URL {
        URL(fileURLWithPath: saveDirectoryPath, isDirectory: true)
    }

    var statusTitle: String {
        isMonitoringEnabled ? "监听中" : "已暂停"
    }

    var statusSymbolName: String {
        isMonitoringEnabled ? "clipboard.fill" : "pause.circle"
    }

    var toggleTitle: String {
        isMonitoringEnabled ? "暂停监听" : "开始监听"
    }

    func toggleMonitoring() {
        setMonitoringEnabled(!isMonitoringEnabled)
    }

    func setMonitoringEnabled(_ enabled: Bool) {
        isMonitoringEnabled = enabled
        defaults.set(enabled, forKey: AppSettingKey.isMonitoringEnabled)
        lastStatusMessage = enabled ? "Monitoring enabled" : "Monitoring paused"
    }

    func setSaveText(_ enabled: Bool) {
        guard canSetContentType(enabled: enabled, current: saveText) else {
            return
        }

        saveText = enabled
        defaults.set(enabled, forKey: AppSettingKey.saveText)
    }

    func setSaveImages(_ enabled: Bool) {
        guard canSetContentType(enabled: enabled, current: saveImages) else {
            return
        }

        saveImages = enabled
        defaults.set(enabled, forKey: AppSettingKey.saveImages)
    }

    func setSaveFiles(_ enabled: Bool) {
        guard canSetContentType(enabled: enabled, current: saveFiles) else {
            return
        }

        saveFiles = enabled
        defaults.set(enabled, forKey: AppSettingKey.saveFiles)
    }

    func setSaveDirectoryPath(_ path: String) {
        guard !path.isEmpty else {
            return
        }

        saveDirectoryPath = path
        defaults.set(path, forKey: AppSettingKey.saveDirectoryPath)
        lastStatusMessage = "Save folder updated"
    }

    func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = saveDirectoryURL

        if panel.runModal() == .OK, let url = panel.url {
            setSaveDirectoryPath(url.path)
        }
    }

    func openSaveDirectory() {
        do {
            try FileManager.default.createDirectory(at: saveDirectoryURL, withIntermediateDirectories: true)
            NSWorkspace.shared.open(saveDirectoryURL)
        } catch {
            lastStatusMessage = "Could not open folder: \(error.localizedDescription)"
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAgentManager.shared.setEnabled(enabled)
            launchAtLogin = enabled
            defaults.set(enabled, forKey: AppSettingKey.launchAtLogin)
            lastStatusMessage = enabled ? "Launch at login enabled" : "Launch at login disabled"
        } catch {
            launchAtLogin = LaunchAgentManager.shared.isEnabled
            defaults.set(launchAtLogin, forKey: AppSettingKey.launchAtLogin)
            lastStatusMessage = error.localizedDescription
        }
    }

    private func canSetContentType(enabled: Bool, current: Bool) -> Bool {
        if enabled || !current {
            return true
        }

        let enabledCount = [saveText, saveImages, saveFiles].filter { $0 }.count
        return enabledCount > 1
    }

    private func save(_ content: ClipboardContent) {
        let directory = saveDirectoryURL
        let options = SaveOptions(saveText: saveText, saveImages: saveImages, saveFiles: saveFiles)

        saveQueue.async { [weak self] in
            do {
                let outcome = try ContentSaver().save(content, to: directory, options: options)

                Task { @MainActor in
                    self?.handleSaveOutcome(outcome)
                }
            } catch {
                Task { @MainActor in
                    self?.lastStatusMessage = "Save failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func handleSaveOutcome(_ outcome: SaveOutcome) {
        switch outcome {
        case let .saved(url):
            lastStatusMessage = "Saved \(url.lastPathComponent)"
        case let .skippedExisting(url):
            lastStatusMessage = "Skipped existing \(url.lastPathComponent)"
        case .skippedEmptyContent:
            lastStatusMessage = "Skipped empty content"
        }
    }
}
