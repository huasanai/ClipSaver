import AppKit
import SwiftUI
import os

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let appState: AppState
    private let logger = Logger(subsystem: "dev.huasan.clipsaver", category: "FolderPicker")
    private var window: NSWindow?

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func show() {
        NSApp.setActivationPolicy(.regular)

        let window = window ?? makeWindow()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let rootView = SettingsView { [weak self] in
            DispatchQueue.main.async {
                self?.chooseSaveDirectory()
            }
        }
            .environmentObject(appState)

        let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
        window.title = "ClipSaver 设置"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(NSSize(width: 620, height: 680))
        window.minSize = NSSize(width: 560, height: 560)
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func chooseSaveDirectory() {
        logger.info("Choose folder requested")

        do {
            try FileManager.default.createDirectory(at: appState.saveDirectoryURL, withIntermediateDirectories: true)
        } catch {
            logger.error("Could not create current save folder before choosing: \(error.localizedDescription, privacy: .public)")
        }

        do {
            guard let selectedPath = try runAppleScriptFolderChooser(defaultPath: appState.saveDirectoryPath) else {
                logger.info("Folder picker cancelled")
                return
            }

            logger.info("Folder picker selected path: \(selectedPath, privacy: .public)")
            appState.setSaveDirectoryPath(selectedPath)
        } catch {
            logger.error("Folder picker failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func runAppleScriptFolderChooser(defaultPath: String) throws -> String? {
        let script = """
        on run argv
            set defaultPath to item 1 of argv
            try
                set defaultFolder to POSIX file defaultPath
                set chosenFolder to choose folder with prompt "选择 ClipSaver 保存文件夹" default location defaultFolder
            on error errorMessage number errorNumber
                if errorNumber is -128 then error number -128
                set chosenFolder to choose folder with prompt "选择 ClipSaver 保存文件夹"
            end try
            return POSIX path of chosenFolder
        end run
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, defaultPath]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return path.isEmpty ? nil : path
        }

        if errorOutput.contains("-128") || errorOutput.localizedCaseInsensitiveContains("user canceled") {
            return nil
        }

        throw FolderPickerError(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

private struct FolderPickerError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message.isEmpty ? "Unknown folder picker error" : message
    }

    var errorDescription: String? {
        message
    }
}
