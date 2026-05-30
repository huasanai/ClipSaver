import Foundation

public enum AppSettingKey {
    public static let saveText = "saveText"
    public static let saveImages = "saveImages"
    public static let saveFiles = "saveFiles"
    public static let saveDirectoryPath = "saveDirectoryPath"
    public static let isMonitoringEnabled = "isMonitoringEnabled"
    public static let launchAtLogin = "launchAtLogin"
}

public enum AppDefaults {
    public static var saveDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("ClipSaver", isDirectory: true)
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/ClipSaver", isDirectory: true)
    }

    public static var saveDirectoryPath: String {
        saveDirectory.path
    }

    public static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            AppSettingKey.saveText: true,
            AppSettingKey.saveImages: true,
            AppSettingKey.saveFiles: true,
            AppSettingKey.saveDirectoryPath: saveDirectoryPath,
            AppSettingKey.isMonitoringEnabled: true,
            AppSettingKey.launchAtLogin: false
        ])
    }
}
