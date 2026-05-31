import AppKit
import ClipSaverCore
import Foundation
import os

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isMonitoringEnabled: Bool
    @Published private(set) var saveText: Bool
    @Published private(set) var saveImages: Bool
    @Published private(set) var saveFiles: Bool
    @Published private(set) var saveDirectoryPath: String
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var fileNamingStrategy: FileNamingStrategy
    @Published private(set) var filenameFormat: String
    @Published private(set) var lastStatusMessage = "Ready"

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "dev.huasan.clipsaver", category: "AppState")
    private let saveQueue = DispatchQueue(label: "dev.huasan.clipsaver.save", qos: .utility)
    private var monitor: ClipboardMonitor?
    private var shortcutController: GlobalShortcutController?
    private var isFilenamePromptActive = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        AppDefaults.register(in: defaults)

        isMonitoringEnabled = defaults.bool(forKey: AppSettingKey.isMonitoringEnabled)
        saveText = defaults.bool(forKey: AppSettingKey.saveText)
        saveImages = defaults.bool(forKey: AppSettingKey.saveImages)
        saveFiles = defaults.bool(forKey: AppSettingKey.saveFiles)
        let storedSaveDirectoryPath = defaults.string(forKey: AppSettingKey.saveDirectoryPath) ?? AppDefaults.saveDirectoryPath
        let normalizedSaveDirectoryPath = URL(fileURLWithPath: storedSaveDirectoryPath, isDirectory: true).standardizedFileURL.path
        saveDirectoryPath = normalizedSaveDirectoryPath
        defaults.set(normalizedSaveDirectoryPath, forKey: AppSettingKey.saveDirectoryPath)
        launchAtLogin = LaunchAgentManager.shared.isEnabled
        fileNamingStrategy = FileNamingStrategy(
            rawValue: defaults.string(forKey: AppSettingKey.fileNamingStrategy) ?? ""
        ) ?? .automatic
        filenameFormat = defaults.string(forKey: AppSettingKey.filenameFormat) ?? "{type}_{timestamp}"
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
        let normalizedPath = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
        guard !normalizedPath.isEmpty else {
            return
        }

        saveDirectoryPath = normalizedPath
        defaults.set(normalizedPath, forKey: AppSettingKey.saveDirectoryPath)
        lastStatusMessage = "Save folder updated"
        logger.info("Save folder updated: \(normalizedPath, privacy: .public)")
    }

    func setFileNamingStrategy(_ strategy: FileNamingStrategy) {
        fileNamingStrategy = strategy
        defaults.set(strategy.rawValue, forKey: AppSettingKey.fileNamingStrategy)
        lastStatusMessage = "Filename mode updated"
    }

    func setFilenameFormat(_ format: String) {
        filenameFormat = format
        defaults.set(format, forKey: AppSettingKey.filenameFormat)
        lastStatusMessage = "Filename format updated"
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
        let naming = FileNamingOptions(strategy: fileNamingStrategy, customFormat: filenameFormat)

        guard options.allows(content) else {
            lastStatusMessage = "Skipped disabled \(content.filenamePrefix) content"
            return
        }

        if naming.strategy == .askEveryTime {
            promptForFilenameAndSave(content, directory: directory, options: options)
            return
        }

        saveQueue.async { [weak self] in
            do {
                let outcome = try ContentSaver().save(
                    content,
                    to: directory,
                    options: options,
                    naming: naming
                )

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

    private func promptForFilenameAndSave(
        _ content: ClipboardContent,
        directory: URL,
        options: SaveOptions
    ) {
        guard !isFilenamePromptActive else {
            lastStatusMessage = "Skipped while filename prompt is open"
            return
        }

        isFilenamePromptActive = true
        let defaultFilename = ContentSaver().makeFilename(for: content)
        let result = FilenamePrompt.show(defaultFilename: defaultFilename)
        isFilenamePromptActive = false

        switch result {
        case .skip:
            lastStatusMessage = "Skipped by user"

        case let .save(filename, stopAsking):
            if stopAsking {
                setFileNamingStrategy(.automatic)
            }

            saveQueue.async { [weak self] in
                do {
                    let outcome = try ContentSaver().save(
                        content,
                        to: directory,
                        options: options,
                        explicitFilename: filename
                    )

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
