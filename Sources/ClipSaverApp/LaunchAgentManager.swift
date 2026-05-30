import Foundation

enum LaunchAgentError: LocalizedError {
    case notRunningFromAppBundle
    case plistSerializationFailed
    case commandFailed(command: String, output: String)

    var errorDescription: String? {
        switch self {
        case .notRunningFromAppBundle:
            return "Launch at login requires running ClipSaver from a .app bundle."
        case .plistSerializationFailed:
            return "Could not serialize the LaunchAgent plist."
        case let .commandFailed(command, output):
            return "\(command) failed: \(output)"
        }
    }
}

final class LaunchAgentManager {
    static let shared = LaunchAgentManager()

    let label = "dev.huasan.clipsaver"

    var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }

    private func enable() throws {
        guard let appBundleURL = Bundle.main.bundleURLIfApp,
              let executableURL = Bundle.main.executableURL
        else {
            throw LaunchAgentError.notRunningFromAppBundle
        }

        let launchAgentsDirectory = plistURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executableURL.path, "--background"],
            "RunAtLoad": true,
            "KeepAlive": false,
            "WorkingDirectory": appBundleURL.deletingLastPathComponent().path
        ]

        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else {
            throw LaunchAgentError.plistSerializationFailed
        }

        try data.write(to: plistURL, options: .atomic)
        _ = try? runLaunchctl(arguments: ["bootout", guiDomain, plistURL.path])
        try runLaunchctl(arguments: ["bootstrap", guiDomain, plistURL.path])
    }

    private func disable() throws {
        _ = try? runLaunchctl(arguments: ["bootout", guiDomain, plistURL.path])

        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    private var guiDomain: String {
        "gui/\(getuid())"
    }

    @discardableResult
    private func runLaunchctl(arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw LaunchAgentError.commandFailed(command: "launchctl \(arguments.joined(separator: " "))", output: output)
        }

        return output
    }
}

private extension Bundle {
    var bundleURLIfApp: URL? {
        bundleURL.pathExtension == "app" ? bundleURL : nil
    }
}
