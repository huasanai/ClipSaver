import Foundation

public enum FileNamingStrategy: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case customFormat
    case askEveryTime

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .automatic:
            return "系统自动命名"
        case .customFormat:
            return "使用命名格式"
        case .askEveryTime:
            return "每次保存前询问"
        }
    }
}

public struct FileNamingOptions: Equatable, Sendable {
    public var strategy: FileNamingStrategy
    public var customFormat: String

    public init(
        strategy: FileNamingStrategy = .automatic,
        customFormat: String = "{type}_{timestamp}"
    ) {
        self.strategy = strategy
        self.customFormat = customFormat
    }
}
