import Foundation

public protocol TimestampProviding {
    func timestamp() -> String
}

public struct SystemTimestampProvider: TimestampProviding {
    private let formatter: DateFormatter

    public init() {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
    }

    public func timestamp() -> String {
        formatter.string(from: Date())
    }
}

public struct FixedTimestampProvider: TimestampProviding {
    private let value: String

    public init(_ value: String) {
        self.value = value
    }

    public func timestamp() -> String {
        value
    }
}
